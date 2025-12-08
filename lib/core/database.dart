library hc_db;

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:convert';
import 'transaction.dart';
import 'cache.dart';
import '../tables/table_manager.dart';
import 'package:logging/logging.dart';

class Database {
  // Обязательные свойства базы данных
  final String directoryPath;
  final String databaseName;
  final TableType tableType;
  final List<String> measurements;
  final List<String> resources;
  final String databasePath;
  final int pageSize;
  final int extentSize;
  final int minReserveExtents;

  // Логгер
  static final Logger _logger = Logger('Database');

  // Управление соединениями
  final Map<String, DatabaseConnection> _connections = {};

  // Менеджер транзакций
  final TransactionManager _transactionManager = TransactionManager();

  // Кэш данных
  final Cache _cache = Cache();

  // Конструктор для создания базы данных с путем и именем
  Database._createDatabase({
    required this.directoryPath,
    required this.databaseName,
    required this.tableType,
    required this.measurements,
    required this.resources,
  }) : assert(directoryPath.isNotEmpty),
       assert(databaseName.isNotEmpty),
       assert(measurements.isNotEmpty),
       assert(resources.isNotEmpty),
       databasePath = '$directoryPath/$databaseName',
       pageSize = 4096,
       extentSize = 65536,
       minReserveExtents = 10;

  // Конструктор для открытия базы данных по имени из config файла
  // Пока в качестве заглушки - для открытия БД по имени
  // необходим так-же конструктор по пути и по пути и имени
  Database.openFromName({
    required this.databaseName,
  }) : directoryPath = '.',
       tableType = TableType.balance, // значение по умолчанию, будет перезаписано из config
       measurements = [],
       resources = [],
       assert(databaseName.isNotEmpty),
       databasePath = './$databaseName',
       pageSize = 4096,
       extentSize = 65536,
       minReserveExtents = 10;

  // Получение менеджера транзакций
  TransactionManager get transactionManager => _transactionManager;

  // Получение кэша
  Cache get cache => _cache;

  // Инициализация базы данных
  Future<void> init() async {
    _logger.fine('Метод init вызван с databasePath: $databasePath');
    _logger.fine('Вызов _initDatabase с $databasePath');
    await _initDatabase();
    _logger.fine('Инициализация компонентов');
    // Инициализация компонентов
    await _cache.init();
    _logger.info('База данных инициализирована');
  }

  // Публичный статический асинхронный фабричный метод
  // Вызывает соответствующий конструктор
  /// Создает физическую структуру базы данных на диске
  ///
  /// @param directoryPath - путь к каталогу для создания базы данных
  /// @param databaseName - название базы данных
  /// @param tableType - тип таблицы
  /// @param measurements - список измерений
  /// @param resources - список ресурсов
  /// @return Future<void> - асинхронная операция создания базы данных
  static Future<Database> createDatabase({
    required String directoryPath,
    required String databaseName,
    required TableType tableType,
    required List<String> measurements,
    required List<String> resources,
  }) async {
    // Проверка входных параметров
    if (directoryPath.isEmpty) {
      throw ArgumentError('Путь к каталогу не может быть пустым или null');
    }
    if (databaseName.isEmpty) {
      throw ArgumentError('Название базы данных не может быть пустым или null');
    }
    if (measurements.isEmpty) {
      throw ArgumentError('Список измерений не может быть пустым или null');
    }
    if (resources.isEmpty) {
      throw ArgumentError('Список ресурсов не может быть пустым или null');
    }

    // Вызываем приватный конструктор
    final database = Database._createDatabase(
      directoryPath: directoryPath,
      databaseName: databaseName,
      tableType: tableType,
      measurements: measurements,
      resources: resources,
    );

    try {
      // Проверяем, существует ли уже такая база данных
      if (await database._databaseExists()) {
        throw StateError('База данных "${database.databaseName}" уже существует');
      }

      // Создаем директорию базы данных
      await database._createDatabaseDirectory();

      // Создаем файл конфигурации
      await database._createConfigFile();

      // Создаем таблицы
      await database._createTables();

      _logger.info(
        'Создана база данных "${database.databaseName}" в каталоге "${database.directoryPath}"',
      );
      _logger.info('Тип таблицы: ${database.tableType}');
      _logger.info('Измерения: ${database.measurements}');
      _logger.info('Ресурсы: ${database.resources}');
    } catch (error, stackTrace) {
      _logger.severe(
        'Ошибка при создании базы данных "$databaseName": $error',
        error,
        stackTrace,
      );
      rethrow;
    }

    // Инициализация базы данных
    await database.init();

    return database;
  }

  // Создание соединения с базой данных
  DatabaseConnection connect(String id) {
    if (_connections.containsKey(id)) {
      return _connections[id]!;
    }

    final connection = DatabaseConnection(id);
    _connections[id] = connection;
    return connection;
  }

  // Закрытие соединения
  void disconnect(String id) {
    _connections.remove(id);
  }

  // Выполнение транзакции
  Future<T> executeTransaction<T>(
    Future<T> Function(Transaction) transactionFunction,
  ) async {
    final transaction = _transactionManager.beginTransaction();
    try {
      final result = await transactionFunction(transaction);
      await transaction.commit();
      return result;
    } catch (e) {
      await transaction.rollback();
      rethrow;
    }
  }

  // Инициализация конкретной базы данных
  Future<void> _initDatabase() async {
    try {
      // Читаем конфигурационный файл базы данных
      final configPath =
          '$databasePath/$databaseName.config';
      final configFile = File(configPath);

      if (!await configFile.exists()) {
        _logger.warning('Конфигурационный файл не найден: $configPath');
        return;
      }

      final configContent = await configFile.readAsString();
      final configData = jsonDecode(configContent);

      // Читаем параметры СУБД
      final pageSize = configData['pageSize'] ?? 4096;
      final extentSize = configData['extentSize'] ?? 65536;
      final minReserveExtents = configData['minReserveExtents'] ?? 10;

      _logger.info('Инициализация базы данных: $databasePath');
      _logger.info(
        'Параметры СУБД - Размер страницы: $pageSize байт, Размер экстента: $extentSize байт, Мин. зарезервированные экстенты: $minReserveExtents',
      );

      // Размечаем файлы под базу данных
      await _allocateDatabaseFiles();

      _logger.info('База данных инициализирована успешно');
    } catch (error, stackTrace) {
      _logger.severe(
        'Ошибка при инициализации базы данных: $error',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  // Разметка файлов под базу данных
  Future<void> _allocateDatabaseFiles() async {
    try {
      _logger.fine('Файлы таблиц созданы, вызываем _markDatabaseFiles');
      // Размечаем файлы под базу данных согласно параметрам
      // Это может включать в себя создание заголовков, резервирование пространства и т.д.
      await _markDatabaseFiles();

      _logger.info('Файлы базы данных размечены успешно');
    } catch (error, stackTrace) {
      _logger.severe(
        'Ошибка при разметке файлов базы данных: $error',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  // Разметка файлов базы данных для инициализации структуры хранения данных.
  //
  // Этот метод выполняет инициализацию файлов базы данных, создавая необходимые
  // заголовки и структуры управления памятью.
  //
  // @param dbName имя базы данных
  Future<void> _markDatabaseFiles() async {
    _logger.info('Начинаем разметку файлов базы данных "$databaseName"');
    _logger.info('Параметры: размер страницы $pageSize байт, размер экстента $extentSize байт, '
        'минимальное количество зарезервированных экстентов: $minReserveExtents');
    try {
      // Создаем заголовки файлов с информацией о структуре БД
      final headerInfo = {
        'databaseName': databaseName,
        'pageSize': pageSize,
        'extentSize': extentSize,
        'minReserveExtents': minReserveExtents,
        'created': DateTime.now().toIso8601String(),
        'version': '1.0.0'
      };

      // Записываем заголовок в каждый файл
      await _writeHeaderToFile('$databasePath/$databaseName.movements', headerInfo);
      await _writeHeaderToFile('$databasePath/$databaseName.aggregations', headerInfo);
      await _writeHeaderToFile('$databasePath/$databaseName.turnovers', headerInfo);

      _logger.info('Файлы базы данных успешно размечены и заголовки записаны');
    } catch (error, stackTrace) {
      _logger.severe('Ошибка при разметке файлов базы данных: $error', error, stackTrace);
      rethrow;
    }
  }

  // Записывает заголовок в указанный файл
  //
  // @param file файл для записи заголовка
  // @param headerInfo информация для записи в заголовок
  Future<void> _writeHeaderToFile(String filePath, Map<String, dynamic> headerInfo) async {
    try {
      File file = File(filePath);
      // Проверяем, существует ли файл
      final fileExists = await file.exists();
      
      // Формируем заголовок в специальном текстовом формате для легкого отделения от данных
      final headerLines = [
        '// DATABASE HEADER',
        '// Generated: ${DateTime.now().toIso8601String()}',
        '// Version: 1.0.0',
        ...headerInfo.entries.map((entry) => '${entry.key}: ${entry.value}'),
        '// END HEADER',
        ''
      ];
      
      final headerContent = headerLines.join('\n');
      
      // Записываем заголовок в файл
      if (!fileExists) {
        // Если файл не существует, создаем его с заголовком
        await file.writeAsString(headerContent);
        _logger.fine('Создан новый файл с заголовком: ${file.path}');
      } else {
        // Для существующего файла записываем заголовок в начало
        // Считываем текущее содержимое
        final currentContent = await file.readAsString();
        // Проверяем, есть ли уже заголовок в файле (по наличию специального маркера)
        if (currentContent.startsWith('// DATABASE HEADER')) {
          _logger.fine('Заголовок уже существует в файле: ${file.path}');
          return;
        } else {
          // Записываем новый контент с заголовком в начало
          await file.writeAsString(headerContent + currentContent);
          _logger.fine('Заголовок добавлен в существующий файл: ${file.path}');
        }
      }
      
      _logger.fine('Заголовок записан в файл: ${file.path}');
    } catch (error, stackTrace) {
      _logger.severe('Не удалось записать заголовок в файл $filePath: $error', error, stackTrace);
      rethrow;
    }
  }

  // Проверяет, существует ли база данных по указанному пути
  Future<bool> _databaseExists() async {
    final directory = Directory('$directoryPath/$databaseName');
    return await directory.exists();
  }

  // Создает директорию базы данных
  Future<void> _createDatabaseDirectory() async {
    final directory = Directory('$directoryPath/$databaseName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  // Создает файл конфигурации базы данных
  Future<void> _createConfigFile() async {
    final configPath = '$directoryPath/$databaseName/$databaseName.config';
    final configFile = File(configPath);

    final configData = {
      'databaseName': databaseName,
      'tableType': tableType.toString(),
      'measurements': measurements,
      'resources': resources,
      'createdAt': DateTime.now().toIso8601String(),
      // Параметры СУБД
      'pageSize': pageSize, // Размер страницы в байтах
      'extentSize': extentSize, // Размер экстента в байтах
      'minReserveExtents':
          minReserveExtents, // Минимальное количество зарезервированных экстентов
    };

    final jsonString = JsonEncoder.withIndent('  ').convert(configData);
    await configFile.writeAsString(jsonString);
  }

  // Создает таблицы базы данных
  Future<void> _createTables() async {
    _logger.fine('Создание таблиц для типа: $tableType');
    // Создаем файлы таблиц в зависимости от типа таблицы
    switch (tableType) {
      case TableType.balance:
        _logger.fine('Создание таблиц баланса: movements и aggregations');
        // Для балансовой таблицы создаем файлы движений и агрегаций
        await _createTableFile('movements');
        await _createTableFile('aggregations');
        break;
      case TableType.turnover:
        _logger.fine('Создание таблиц оборотов: movements и movements');
        // Для таблицы оборотов создаем файлы движений и оборотов
        await _createTableFile('movements');
        await _createTableFile('turnovers');
        break;
      case TableType.universal:
        _logger.fine('Создание универсальных таблиц: movements, aggregations и turnovers');
        // Для универсальной таблицы создаем все файлы
        await _createTableFile('movements');
        await _createTableFile('aggregations');
        await _createTableFile('turnovers');
        break;
    }
  }

  // Создает файл таблицы
  Future<void> _createTableFile(String tableName) async {
    final tablePath = '${databasePath}/${databaseName}.$tableName';
    final tableFile = File(tablePath);
    _logger.fine('Создаем файл таблицы: $tablePath');
    await tableFile.create();
    _logger.fine('Файл таблицы создан: $tablePath');
  }

}

// Соединение с базой данных
class DatabaseConnection {
  final String id;
  bool _isOpen = false;

  DatabaseConnection(this.id);

  bool get isOpen => _isOpen;

  // Открытие соединения
  void open() {
    _isOpen = true;
    print('Соединение $id открыто');
  }

  // Закрытие соединения
  void close() {
    _isOpen = false;
    print('Соединение $id закрыто');
  }
}

