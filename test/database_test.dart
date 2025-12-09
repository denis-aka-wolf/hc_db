import 'package:test/test.dart';
import 'package:hc_db/hc_db.dart';
import 'dart:io';

// Список созданных баз данных для последующего удаления
final List<String> createdDatabases = [];

void main() {
  group('Create Database', () {
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
        databaseName: 'test_db_balance',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_balance');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_balance');
      expect(db.tableType, TableType.balance);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
    
    test('Database creation with turnover table type', () async {
      // Тестируем создание базы данных с типом таблицы turnover
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_turnover',
        tableType: TableType.turnover,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_turnover');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_turnover');
      expect(db.tableType, TableType.turnover);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
    
    test('Database creation with universal table type', () async {
      // Тестируем создание базы данных с типом таблицы universal
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_universal',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_universal');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_universal');
      expect(db.tableType, TableType.universal);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
  });
}