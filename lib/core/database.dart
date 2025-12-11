library;

import '../imports.dart';
import 'validation_service.dart';
import 'config_manager.dart';
import 'file_manager.dart';
import 'table_manager_service.dart';

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

  // Параметры логирования
  final Level logLevel;
  final String? logFilePath;
  final int maxLogFileSize; // в байтах
  final int maxLogFilesCount; // количество файлов для ротации

  // Логгер
  static final Logger _logger = Logger('Database');

  // Менеджер логирования
  DatabaseLogger? _databaseLogger;

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
    this.logLevel = Level.INFO,
    logFilePath,
    this.maxLogFileSize = 10485760, // 10MB
    this.maxLogFilesCount = 5,
  }) : assert(directoryPath.isNotEmpty),
       assert(databaseName.isNotEmpty),
       assert(measurements.isNotEmpty),
       assert(resources.isNotEmpty),
       databasePath = '$directoryPath/$databaseName',
       this.logFilePath = (logFilePath == null || logFilePath.isEmpty)
           ? '$directoryPath/$databaseName/logs/database.log'
           : logFilePath,
       pageSize = 4096,
       extentSize = 65536,
       minReserveExtents = 10;

  // Приватный конструктор для открытия существующей базы данных с параметрами из конфига
  Database._openDatabase({
    required this.directoryPath,
    required this.databaseName,
    required this.tableType,
    required this.measurements,
    required this.resources,
    required this.databasePath,
    required this.pageSize,
    required this.extentSize,
    required this.minReserveExtents,
    required this.logLevel,
    required this.logFilePath,
    required this.maxLogFileSize,
    required this.maxLogFilesCount,
  });

  // Получение менеджера транзакций
  TransactionManager get transactionManager => _transactionManager;

  // Получение кэша
  Cache get cache => _cache;

  // Инициализация базы данных
  Future<void> init() async {
    _logger.fine('Метод init вызван с databasePath: $databasePath');
    _logger.fine('Вызов _initDatabase с $databasePath');

    // Настройка логирования в файл
    await _setupFileLogging();

    final fileManager = FileManager(
      directoryPath: directoryPath,
      databaseName: databaseName,
      tableType: tableType,
      measurements: measurements,
      resources: resources,
      logLevel: logLevel,
      logFilePath: logFilePath,
      maxLogFileSize: maxLogFileSize,
      maxLogFilesCount: maxLogFilesCount,
      pageSize: pageSize,
      extentSize: extentSize,
      minReserveExtents: minReserveExtents,
    );
    await fileManager.initDatabase();

    _logger.fine('Инициализация компонентов');
    // Инициализация компонентов
    await _cache.init();
    _logger.info('База данных инициализирована');
  }

  // Метод для открытия существующей базы данных
  static Future<Database> open({
    required String directoryPath,
    required String databaseName,
  }) async {
    await ValidationService.validateDirectoryPath(directoryPath);
    await ValidationService.validateDatabaseName(databaseName);

    TableType tableType = TableType.balance;
    List<String> measurements = [];
    List<String> resources = [];
    String databasePath = '$directoryPath/$databaseName';
    int pageSize = 4096;
    int extentSize = 65536;
    int minReserveExtents = 10;
    Level logLevel = Level.INFO;
    String? logFilePath;
    int maxLogFileSize = 10485760; // 10MB
    int maxLogFilesCount = 5;

    // Проверяем, существует ли база данных
    final dbDir = Directory(databasePath);
    if (!await dbDir.exists()) {
      throw StateError(
        'База данных "$databaseName" не существует в каталоге "$directoryPath"',
      );
    }

    // Читаем конфигурационный файл для получения параметров
    final configPath = '$databasePath/$databaseName.config';
    final configFile = File(configPath);

    if (await configFile.exists()) {
      final configContent = await configFile.readAsString();
      final configData = jsonDecode(configContent);

      tableType = ConfigManager.getTableTypeFromStringStatic(
        configData['tableType'] ?? 'balance',
      );
      measurements = List<String>.from(configData['measurements'] ?? []);
      resources = List<String>.from(configData['resources'] ?? []);
      extentSize = configData['extentSize'] ?? 65536;
      minReserveExtents = configData['minReserveExtents'] ?? 10;
      pageSize = configData['pageSize'] ?? 4096;

      // Параметры логирования
      if (configData.containsKey('logging')) {
        final loggingConfig = configData['logging'];
        if (loggingConfig is Map<String, dynamic>) {
          if (loggingConfig.containsKey('level')) {
            String levelStr = loggingConfig['level'] as String? ?? 'INFO';
            logLevel = ConfigManager.getLogLevelFromStringStatic(levelStr);
          }
          if (loggingConfig.containsKey('filePath')) {
            logFilePath = loggingConfig['filePath'] as String?;
          }
          if (loggingConfig.containsKey('maxFileSize')) {
            maxLogFileSize = loggingConfig['maxFileSize'] as int? ?? 10485760;
          }
          if (loggingConfig.containsKey('maxFilesCount')) {
            maxLogFilesCount = loggingConfig['maxFilesCount'] as int? ?? 5;
          }
        }
      }
    }

    // Создаем экземпляр базы данных с параметрами из конфига
    final database = Database._openDatabase(
      directoryPath: directoryPath,
      databaseName: databaseName,
      tableType: tableType,
      measurements: measurements,
      resources: resources,
      databasePath: databasePath,
      extentSize: extentSize,
      minReserveExtents: minReserveExtents,
      pageSize: pageSize,
      logLevel: logLevel,
      logFilePath: logFilePath,
      maxLogFileSize: maxLogFileSize,
      maxLogFilesCount: maxLogFilesCount,
    );

    try {
      // Инициализация базы данных
      await database.init();

      _logger.info(
        'Открыта база данных "${database.databaseName}" из каталога "${database.directoryPath}"',
      );
      _logger.info('Тип таблицы: ${database.tableType}');
      _logger.info('Измерения: ${database.measurements}');
      _logger.info('Ресурсы: ${database.resources}');

      return database;
    } catch (error, stackTrace) {
      _logger.severe(
        'Ошибка при открытии базы данных "$databaseName": $error',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Публичный статичный асинхронный фабричный метод
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
    await ValidationService.validateDirectoryPath(directoryPath);
    await ValidationService.validateDatabaseName(databaseName);
    if (measurements.isEmpty) {
      throw ArgumentError('Список измерений не может быть пустым');
    }
    if (resources.isEmpty) {
      throw ArgumentError('Список ресурсов не может быть пустым');
    }

    // Валидируем названия измерений и ресурсов
    ValidationService.validateMeasurementOrResourceNames(
      measurements,
      'измерения',
    );
    ValidationService.validateMeasurementOrResourceNames(resources, 'ресурсы');

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
      final fileManager = FileManager(
        directoryPath: database.directoryPath,
        databaseName: database.databaseName,
        tableType: database.tableType,
        measurements: database.measurements,
        resources: database.resources,
        logLevel: database.logLevel,
        logFilePath: database.logFilePath,
        maxLogFileSize: database.maxLogFileSize,
        maxLogFilesCount: database.maxLogFilesCount,
        pageSize: database.pageSize,
        extentSize: database.extentSize,
        minReserveExtents: database.minReserveExtents,
      );

      if (await fileManager.databaseExists()) {
        throw StateError(
          'База данных "${database.databaseName}" уже существует',
        );
      }

      // Создаем директорию базы данных
      await fileManager.createDatabaseDirectory();

      // Создаем файл конфигурации
      final configManager = ConfigManager(
        directoryPath: database.directoryPath,
        databaseName: database.databaseName,
        tableType: database.tableType,
        measurements: database.measurements,
        resources: database.resources,
        logLevel: database.logLevel,
        logFilePath: database.logFilePath,
        maxLogFileSize: database.maxLogFileSize,
        maxLogFilesCount: database.maxLogFilesCount,
      );
      await configManager.createConfigFile();

      // Создаем таблицы
      final tableManager = TableManagerService(
        directoryPath: database.directoryPath,
        databaseName: database.databaseName,
        tableType: database.tableType,
        measurements: database.measurements,
        resources: database.resources,
      );
      await tableManager.createTables();

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

  /// Настраивает логирование в файл
  Future<void> _setupFileLogging() async {
    _databaseLogger = DatabaseLogger(
      logLevel: logLevel,
      logFilePath: logFilePath,
      maxLogFileSize: maxLogFileSize,
      maxLogFilesCount: maxLogFilesCount,
    );

    await _databaseLogger!.setupFileLogging();
  }

  /// Закрывает логирование и освобождает ресурсы
  Future<void> closeLogging() async {
    await _databaseLogger?.closeLogging();
  }

  // Закрывает все соединения и освобождает ресурсы базы данных
  Future<void> close() async {
    // Закрываем все соединения
    for (final connection in _connections.values) {
      if (connection.isOpen) {
        connection.close();
      }
    }
    _connections.clear();

    // Закрываем логирование
    await closeLogging();

    _logger.info('База данных закрыта');
  }
}
