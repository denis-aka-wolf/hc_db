import 'package:test/test.dart';
import 'package:hc_db/hc_db.dart';
import 'dart:io';

// Список созданных баз данных для последующего удаления
final List<String> createdDatabases = [];

void main() {
 group('Database Creation Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database creation with parameters', () async {
      // Тестируем создание базы данных с параметрами
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db');
      expect(db.tableType, TableType.balance);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });

    test('Database initialization', () async {
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_init',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_init');
      
      await db.init();
      // Проверяем, что база данных инициализирована без ошибок
      expect(true, true);
    });
    
    test('Database creation with balance table type', () async {
      // Тестируем создание базы данных с типом таблицы balance
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_balance_unique',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_balance_unique');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_balance_unique');
      expect(db.tableType, TableType.balance);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
    
    test('Database creation with turnover table type', () async {
      // Тестируем создание базы данных с типом таблицы turnover
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_turnover_unique',
        tableType: TableType.turnover,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_turnover_unique');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_turnover_unique');
      expect(db.tableType, TableType.turnover);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
    
    test('Database creation with universal table type', () async {
      // Тестируем создание базы данных с типом таблицы universal
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_universal_unique',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_universal_unique');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_universal_unique');
      expect(db.tableType, TableType.universal);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
  });
  
  group('Database Files Creation Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database files creation for balance type', () async {
      // Тестируем создание файлов базы данных с типом balance
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_files_balance',
        tableType: TableType.balance,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_files_balance');
      
      // Проверяем, что база данных создана с правильными файлами
      final dbDir = Directory('./db/test_db_files_balance');
      expect(await dbDir.exists(), true);
      
      // Для типа balance должны быть созданы файлы movements и aggregations
      final movementsFile = File('./db/test_db_files_balance/test_db_files_balance.movements');
      final aggregationsFile = File('./db/test_db_files_balance/test_db_files_balance.aggregations');
      final turnoversFile = File('./db/test_db_files_balance/test_db_files_balance.turnovers');
      
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), false); // turnovers не должен создаваться для типа balance
    });
    
    test('Database files creation for turnover type', () async {
      // Тестируем создание файлов базы данных с типом turnover
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_files_turnover',
        tableType: TableType.turnover,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_files_turnover');
      
      // Проверяем, что база данных создана с правильными файлами
      final dbDir = Directory('./db/test_db_files_turnover');
      expect(await dbDir.exists(), true);
      
      // Для типа turnover должны быть созданы файлы movements и turnovers
      final movementsFile = File('./db/test_db_files_turnover/test_db_files_turnover.movements');
      final turnoversFile = File('./db/test_db_files_turnover/test_db_files_turnover.turnovers');
      final aggregationsFile = File('./db/test_db_files_turnover/test_db_files_turnover.aggregations');
      
      expect(await movementsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
      expect(await aggregationsFile.exists(), false); // aggregations не должен создаваться для типа turnover
    });
    
    test('Database files creation for universal type', () async {
      // Тестируем создание файлов базы данных с типом universal
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_files_universal',
        tableType: TableType.universal,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_files_universal');
      
      // Проверяем, что база данных создана с правильными файлами
      final dbDir = Directory('./db/test_db_files_universal');
      expect(await dbDir.exists(), true);
      
      // Для типа universal должны быть созданы файлы movements, aggregations и turnovers
      final movementsFile = File('./db/test_db_files_universal/test_db_files_universal.movements');
      final aggregationsFile = File('./db/test_db_files_universal/test_db_files_universal.aggregations');
      final turnoversFile = File('./db/test_db_files_universal/test_db_files_universal.turnovers');
      
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
    });
    
    test('Database config file creation', () async {
      // Тестируем создание файла конфигурации
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_config',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_config');
      
      // Проверяем, что файл конфигурации создан
      final configFile = File('./db/test_db_config/test_db_config.config');
      expect(await configFile.exists(), true);
      
      // Проверяем содержимое файла конфигурации
      final configContent = await configFile.readAsString();
      expect(configContent.contains('databaseName'), true);
      expect(configContent.contains('tableType'), true);
      expect(configContent.contains('measurements'), true);
      expect(configContent.contains('resources'), true);
    });
    
    test('Database creation with same name should throw error', () async {
      // Создаем базу данных
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_duplicate',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_duplicate');
      
      // Пробуем создать базу данных с тем же именем - должно вызвать ошибку
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: 'test_db_duplicate',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}