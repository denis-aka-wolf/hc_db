import 'package:test/test.dart';
import 'dart:io';
import 'package:hc_db/hc_db.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

void main() {
  group('Database Logging Tests', () {
    final testDir = './db';
    final dbName = 'logging_test_db';
    final logFilePath = './logs/test_database.log';

    setUp(() async {
      // Создаем директорию для тестовой базы данных
      await Directory(testDir).create(recursive: true);
      
      // Удаляем файл лога, если он существует
      if (await File(logFilePath).exists()) {
        await File(logFilePath).delete();
      }
      
      // Создаем директорию для логов
      await Directory('./logs').create(recursive: true);
    });

    test('Create database with logging configuration', () async {
      final testDbName = '${dbName}_create';
      // Создаем базу данных с настройками логирования
      final database = await Database.createDatabase(
        directoryPath: testDir,
        databaseName: testDbName,
        tableType: TableType.balance,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );

      expect(database, isNotNull);
      expect(await Directory('$testDir/$testDbName').exists(), isTrue);
      
      // Проверяем, что база данных была создана с настройками логирования по умолчанию
      expect(database.logLevel, equals(Level.INFO));
      expect(database.logFilePath, isNotNull); // Теперь путь к логу задан по умолчанию
      expect(database.logFilePath, equals('$testDir/$testDbName/logs/database.log'));
      
      // Закрываем логирование
      await database.closeLogging();
    });

    test('Open database with logging configuration from file', () async {
      final testDbName = '${dbName}_open';
      // Сначала создадим базу данных
      final database = await Database.createDatabase(
        directoryPath: testDir,
        databaseName: testDbName,
        tableType: TableType.balance,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Закрываем соединение
      await database.closeLogging();
      
      // Модифицируем конфигурационный файл, чтобы добавить настройки логирования
      final configFile = File('$testDir/$testDbName/$testDbName.config');
      final configContent = await configFile.readAsString();
      final configMap = await json.decode(configContent) as Map<String, dynamic>;
      
      // Добавляем настройки логирования
      configMap['logging'] = {
        'level': 'FINE',
        'filePath': logFilePath,
        'maxFileSize': 1048576, // 1MB
        'maxFilesCount': 3,
      };
      
      await configFile.writeAsString(JsonEncoder.withIndent('  ').convert(configMap));
      
      // Открываем базу данных с новыми настройками
      final openedDatabase = await Database.open(
        directoryPath: testDir,
        databaseName: testDbName,
      );
      
      expect(openedDatabase, isNotNull);
      expect(openedDatabase.logLevel, equals(Level.FINE));
      expect(openedDatabase.logFilePath, equals(logFilePath));
      expect(openedDatabase.maxLogFileSize, equals(1048576));
      expect(openedDatabase.maxLogFilesCount, equals(3));
      
      // Закрываем логирование
      await openedDatabase.closeLogging();
    });

    test('File logging functionality', () async {
      final testDbName = '${dbName}_file';
      // Сначала создадим базу данных
      final database = await Database.createDatabase(
        directoryPath: testDir,
        databaseName: testDbName,
        tableType: TableType.balance,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Закрываем соединение
      await database.closeLogging();
      
      // Модифицируем конфигурационный файл, чтобы включить логирование в файл
      final configFile = File('$testDir/$testDbName/$testDbName.config');
      final configContent = await configFile.readAsString();
      final configMap = await json.decode(configContent) as Map<String, dynamic>;
      
      // Добавляем настройки логирования
      configMap['logging'] = {
        'level': 'INFO',
        'filePath': logFilePath,
        'maxFileSize': 1048576, // 1MB
        'maxFilesCount': 3,
      };
      
      await configFile.writeAsString(JsonEncoder.withIndent(' ').convert(configMap));
      
      // Открываем базу данных с настройками логирования в файл
      final db = await Database.open(
        directoryPath: testDir,
        databaseName: testDbName,
      );
      
      // Создаем соединение и выполняем простую операцию для генерации лога
      final connection = db.connect('test_connection');
      connection.open();
      
      // Ждем немного, чтобы логи записались
      await Future.delayed(Duration(seconds: 1));
      
      // Проверяем, что файл лога был создан
      expect(await File(logFilePath).exists(), isTrue);
      
      // Читаем файл лога и проверяем, что в нем есть записи
      final logContent = await File(logFilePath).readAsString();
      expect(logContent, contains('[INFO]'));
      expect(logContent, contains('Database'));
      
      // Закрываем соединение
      connection.close();
      
      // Закрываем логирование
      await db.closeLogging();
    });

    tearDown(() async {
      // Удаляем директорию с тестовой базой данных
      if (await Directory(testDir).exists()) {
        await Directory(testDir).delete(recursive: true);
      }
      
      // Удаляем директорию с логами
      if (await Directory('./logs').exists()) {
        await Directory('./logs').delete(recursive: true);
      }
    });
  });
}