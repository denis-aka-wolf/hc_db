library;

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
    await _validateDirectoryPath(directoryPath);
    await _validateDatabaseName(databaseName);
    if (measurements.isEmpty) {
      throw ArgumentError('Список измерений не может быть пустым');
    }
    if (resources.isEmpty) {
      throw ArgumentError('Список ресурсов не может быть пустым');
    }
    
    // Валидируем названия измерений и ресурсов
    _validateMeasurementOrResourceNames(measurements, 'измерения');
    _validateMeasurementOrResourceNames(resources, 'ресурсы');

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

  /// Проверяет корректность пути к каталогу
  /// 
  /// Выполняет проверки:
  /// - Путь не пустой
  /// - Каталог существует
  /// - Указанный путь является каталогом, а не файлом
  /// 
  /// @param directoryPath путь к каталогу для проверки
  /// @throws ArgumentError если путь некорректный
 static Future<void> _validateDirectoryPath(String directoryPath) async {
    // Проверка на пустоту
    if (directoryPath.isEmpty) {
      throw ArgumentError('Путь к каталогу не может быть пустым');
    }
    
    // Проверка корректности пути и типа
    try {
      final directory = Directory(directoryPath);
      
      // Используем '!' для уверенности, что directory.exists() не вернет null,
      // хотя в данном случае он возвращает Future<bool>.
      if (!await directory.exists()) {
        throw ArgumentError('Каталог не существует: $directoryPath');
      }
        
      final stat = await directory.stat();
      if (stat.type != FileSystemEntityType.directory) {
        throw ArgumentError('Указанный путь не является каталогом: $directoryPath');
      }
    } catch (e) {
      // Используем короткий оператор '??' для обработки типа исключения.
      // Если 'e' является ArgumentError, перебрасываем 'e', иначе создаем новое.
      throw (e is ArgumentError) 
        ? e 
        : ArgumentError('Некорректный путь каталогу: $directoryPath (${e.toString()})');
    }
  }

  /// Проверяет корректность названия базы данных
  ///
  /// Название базы данных должно:
  /// - Не быть пустым
  /// - Начинаться с буквы
  /// - Содержать только латинские буквы, цифры, символы '-' и '_'
  ///
  /// @param databaseName название базы данных для проверки
  /// @throws ArgumentError если название некорректно
  static Future<void> _validateDatabaseName(String databaseName) async {
    // Проверка на пустоту
    if (databaseName.isEmpty) {
      throw ArgumentError('Название базы данных не может быть пустым');
    }
    
    // Проверка, что первым символом является буква
    if (!RegExp(r'^[a-zA-Z]').hasMatch(databaseName)) {
      throw ArgumentError('Название базы данных должно начинаться с буквы');
    }
    
    // Проверка, что все символы соответствуют допустимым
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(databaseName)) {
      throw ArgumentError('Название базы данных может содержать только латинские буквы, цифры, символы "-" и "_"');
    }
  }

  /// Проверяет корректность названия измерения или ресурса
  ///
  /// Название измерения или ресурса должно:
  /// - Не быть пустым
  /// - Начинаться с буквы
  /// - Содержать только латинские буквы, цифры, символы '-' и '_'
  ///
  /// @param name название измерения или ресурса для проверки
  /// @throws ArgumentError если название некорректно
  static bool _isValidMeasurementOrResourceName(String name) {
    // Проверка на пустоту
    if (name.isEmpty) {
      return false;
    }
    
    // Проверка, что первым символом является буква
    if (!RegExp(r'^[a-zA-Z]').hasMatch(name)) {
      return false;
    }
    
    // Проверка, что все символы соответствуют допустимым
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name)) {
      return false;
    }
    
    return true;
  }

  /// Валидирует список названий измерений или ресурсов
  ///
  /// @param names список названий для валидации
  /// @param type тип названий ('измерения' или 'ресурсы') для сообщений об ошибках
  /// @throws ArgumentError если какие-либо названия некорректны
  static void _validateMeasurementOrResourceNames(List<String> names, String type) {
    for (final name in names) {
      if (!_isValidMeasurementOrResourceName(name)) {
        throw ArgumentError('Некорректное название $type: "$name". Название должно начинаться с буквы и содержать только латинские буквы, цифры, символы "-" и "_"');
      }
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
      _logger.fine('Подготовим файлы таблиц');
      // Размечаем файлы под базу данных согласно параметрам
      await _markDatabaseFiles();

      _logger.info('Файлы таблиц данных подготовлены');
    } catch (error, stackTrace) {
      _logger.severe(
        'Ошибка при подготовке файлов таблиц данных: $error',
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
    
    // Резервируем дисковое пространство для файлов таблиц
    await _reserveDiskSpace();

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

      // Проверяем существующие файлы и записываем заголовок только в те, которые существуют
      final movementsPath = '$databasePath/$databaseName.movements';
      final aggregationsPath = '$databasePath/$databaseName.aggregations';
      final turnoversPath = '$databasePath/$databaseName.turnovers';
      
      // Проверяем и записываем заголовок в файл движений, если он существует
      final movementsFile = File(movementsPath);
      if (await movementsFile.exists()) {
        await _writeHeaderToFile(movementsPath, headerInfo);
      }
      
      // Проверяем и записываем заголовок в файл агрегаций, если он существует
      final aggregationsFile = File(aggregationsPath);
      if (await aggregationsFile.exists()) {
        await _writeHeaderToFile(aggregationsPath, headerInfo);
      }
      
      // Проверяем и записываем заголовок в файл оборотов, если он существует
      final turnoversFile = File(turnoversPath);
      if (await turnoversFile.exists()) {
        await _writeHeaderToFile(turnoversPath, headerInfo);
      }

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
        // Для существующего файла проверяем, есть ли уже заголовок
        // Считываем текущее содержимое
        final currentContent = await file.readAsString();
        
        // Проверяем, есть ли уже заголовок в файле (по наличию специального маркера)
        // Используем более точную проверку, чтобы избежать проблем с пробелами
        final trimmedContent = currentContent.trimLeft();
        if (trimmedContent.startsWith('// DATABASE HEADER')) {
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

  // Резервирует дисковое пространство для файлов таблиц
  Future<void> _reserveDiskSpace() async {
    _logger.fine('Резервируем дисковое пространство для файлов таблиц');
    try {
      // Получаем пути к файлам таблиц
      final movementsPath = '$databasePath/$databaseName.movements';
      final aggregationsPath = '$databasePath/$databaseName.aggregations';
      final turnoversPath = '$databasePath/$databaseName.turnovers';
      
      // Увеличиваем размер файлов таблиц (только если файлы существуют)
      await _increaseFileSizeIfExists(movementsPath);
      await _increaseFileSizeIfExists(aggregationsPath);
      await _increaseFileSizeIfExists(turnoversPath);
      
      _logger.info('Дисковое пространство успешно зарезервировано');
    } catch (error, stackTrace) {
      _logger.severe('Ошибка при резервировании дискового пространства: $error', error, stackTrace);
      rethrow;
    }
  }

  // Увеличивает размер файла до указанного размера
  Future<void> _increaseFileSize(String filePath) async {
    // Рассчитываем размер резерва: минимальное количество экстентов * размер экстента
    final reserveSize = minReserveExtents * extentSize;
    _logger.fine('Размер резерва: $reserveSize байт');
    try {
      final file = File(filePath);
      final currentSize = await file.length();
      _logger.fine('Текущий размер файла $filePath: $currentSize байт');
      // !!! РЕФАКТОРИНГ !!! учитывать и свободное место
      if (currentSize < reserveSize) {
        _logger.fine('Увеличиваем размер файла $filePath до $reserveSize байт');
        final RandomAccessFile randomAccessFile = await file.open(mode: FileMode.write);
        await randomAccessFile.truncate(reserveSize);
        await randomAccessFile.close();
        final newSize = await file.length();
        _logger.fine('Размер файла $filePath увеличен до $newSize байт (ожидалось $reserveSize)');
      } else {
        _logger.fine('Файл $filePath уже имеет достаточный размер: $currentSize байт');
      }
    } catch (error, stackTrace) {
      _logger.severe('Ошибка при увеличении размера файла $filePath: $error', error, stackTrace);
      rethrow;
    }
  }
  
  // Увеличивает размер файла до указанного размера, если файл существует
  Future<void> _increaseFileSizeIfExists(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await _increaseFileSize(filePath);
      } else {
        _logger.fine('Файл $filePath не существует, пропускаем увеличение размера');
      }
    } catch (error, stackTrace) {
      _logger.severe('Ошибка при проверке существования файла $filePath: $error', error, stackTrace);
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
    final tablePath = '$databasePath/$databaseName.$tableName';
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

