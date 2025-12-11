library;

import '../imports.dart';

class ConfigManager {
  final String directoryPath;
  final String databaseName;
  final TableType tableType;
  final List<String> measurements;
  final List<String> resources;
  final int pageSize;
  final int extentSize;
  final int minReserveExtents;
  final Level logLevel;
  final String? logFilePath;
  final int maxLogFileSize;
  final int maxLogFilesCount;

  late final String databasePath;

  ConfigManager({
    required this.directoryPath,
    required this.databaseName,
    required this.tableType,
    required this.measurements,
    required this.resources,
    this.logLevel = Level.INFO,
    this.logFilePath,
    this.maxLogFileSize = 10485760, // 10MB
    this.maxLogFilesCount = 5,
  }) : assert(directoryPath.isNotEmpty),
        assert(databaseName.isNotEmpty),
        assert(measurements.isNotEmpty),
        assert(resources.isNotEmpty),
        databasePath = '$directoryPath/$databaseName',
        pageSize = 4096,
        extentSize = 65536,
        minReserveExtents = 10;

  ConfigManager.fromExisting({
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

  /// Загрузка конфигурации из файла
  Future<Map<String, dynamic>?> loadConfiguration() async {
    try {
      final configPath = '$databasePath/$databaseName.config';
      final configFile = File(configPath);

      if (!await configFile.exists()) {
        _logger.warning('Конфигурационный файл не найден: $configPath');
        return null;
      }

      final configContent = await configFile.readAsString();
      final configData = jsonDecode(configContent);

      _logger.info('Конфигурация загружена из файла: $configPath');

      return configData;
    } catch (error, stackTrace) {
      _logger.severe(
        'Ошибка при загрузке конфигурации: $error',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Создание файла конфигурации базы данных
  Future<void> createConfigFile() async {
    final configPath = '$databasePath/$databaseName.config';
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
      // Параметры логирования
      'logging': {
        'level': logLevel.name,
        'filePath': logFilePath,
        'maxFileSize': maxLogFileSize,
        'maxFilesCount': maxLogFilesCount,
      }
    };

    final jsonString = JsonEncoder.withIndent('  ').convert(configData);
    await configFile.writeAsString(jsonString);
  }

  /// Преобразование строки в TableType
 TableType getTableTypeFromString(String typeString) {
    switch (typeString) {
      case 'TableType.balance':
        return TableType.balance;
      case 'TableType.turnover':
        return TableType.turnover;
      case 'TableType.universal':
        return TableType.universal;
      default:
        return TableType.balance;
    }
  }

  /// Получение уровня логирования из строки
  Level getLogLevelFromString(String levelStr) {
    switch (levelStr.toUpperCase()) {
      case 'ALL':
        return Level.ALL;
      case 'FINEST':
        return Level.FINEST;
      case 'FINER':
        return Level.FINER;
      case 'FINE':
        return Level.FINE;
      case 'CONFIG':
        return Level.CONFIG;
      case 'INFO':
        return Level.INFO;
      case 'WARNING':
        return Level.WARNING;
      case 'SEVERE':
        return Level.SEVERE;
      case 'SHOUT':
        return Level.SHOUT;
      case 'OFF':
        return Level.OFF;
      default:
        return Level.INFO;
    }
  }
  
  /// Статический метод для преобразования строки в TableType
 static TableType getTableTypeFromStringStatic(String typeString) {
    switch (typeString) {
      case 'TableType.balance':
        return TableType.balance;
      case 'TableType.turnover':
        return TableType.turnover;
      case 'TableType.universal':
        return TableType.universal;
      default:
        return TableType.balance;
    }
  }

  /// Статический метод для получения уровня логирования из строки
  static Level getLogLevelFromStringStatic(String levelStr) {
    switch (levelStr.toUpperCase()) {
      case 'ALL':
        return Level.ALL;
      case 'FINEST':
        return Level.FINEST;
      case 'FINER':
        return Level.FINER;
      case 'FINE':
        return Level.FINE;
      case 'CONFIG':
        return Level.CONFIG;
      case 'INFO':
        return Level.INFO;
      case 'WARNING':
        return Level.WARNING;
      case 'SEVERE':
        return Level.SEVERE;
      case 'SHOUT':
        return Level.SHOUT;
      case 'OFF':
        return Level.OFF;
      default:
        return Level.INFO;
    }
  }

  static final Logger _logger = Logger('ConfigManager');
}