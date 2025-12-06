import 'package:test/test.dart';
import 'package:hc_db/hc_db.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group('HC Database Tests', () {
    test('Database singleton creation', () {
      final db1 = Database();
      final db2 = Database();
      expect(db1, same(db2));
    });

    test('Database initialization', () async {
      final db = Database();
      await db.init();
      // Проверяем, что база данных инициализирована без ошибок
      expect(true, true);
    });

    test('Table creation', () {
      final db = Database();
      final tableManager = TableManager(db);
      
      final table = Table(
        name: 'test_table',
        type: TableType.balance,
        measurements: ['wallet_address'],
        resources: ['amount'],
      );
      
      // Проверяем создание таблицы
      expect(() => tableManager.createTable(table), returnsNormally);
    });

    test('Transaction management', () {
      final db = Database();
      final transactionManager = db.transactionManager;
      
      final transaction = transactionManager.beginTransaction();
      expect(transaction, isNotNull);
      expect(transaction.isCommitted, isFalse);
      expect(transaction.isRolledBack, isFalse);
    });

    group('Database Creation Tests', () {
      late String testDirectory;
      
      setUp(() {
        // Создаем временную директорию для тестов
        testDirectory = '${Directory.systemTemp.path}/test_database_${DateTime.now().millisecondsSinceEpoch}';
        Directory(testDirectory).createSync(recursive: true);
      });
      
      tearDown(() {
        // Очищаем тестовую директорию после каждого теста
        if (Directory(testDirectory).existsSync()) {
          Directory(testDirectory).deleteSync(recursive: true);
        }
      });
      
      test('Create database with valid parameters', () async {
        final db = Database();
        
        // Тестируем создание базы данных с корректными параметрами
        await db.createDatabase(
          testDirectory,
          'test_db',
          TableType.balance,
          ['measurement1', 'measurement2'],
          ['resource1', 'resource2'],
        );
        
        // Проверяем, что директория была создана
        final dbDirectory = Directory('$testDirectory/test_db');
        expect(dbDirectory.existsSync(), isTrue);
        
        // Проверяем наличие конфигурационного файла
        final configFile = File('$testDirectory/test_db/test_db.config');
        expect(configFile.existsSync(), isTrue);
        
        // Проверяем наличие файлов таблиц
        expect(File('$testDirectory/test_db/test_db.movements').existsSync(), isTrue);
        expect(File('$testDirectory/test_db/test_db.aggregations').existsSync(), isTrue);
        expect(File('$testDirectory/test_db/test_db.turnovers').existsSync(), isTrue);
      });
      
      test('Create database with empty directory path', () {
        final db = Database();
        
        expect(
          () => db.createDatabase(
            '',
            'test_db',
            TableType.balance,
            ['measurement1'],
            ['resource1'],
          ),
          throwsA(predicate((e) => e is ArgumentError && e.message.contains('Путь к каталогу'))),
        );
      });
      
      test('Create database with empty database name', () {
        final db = Database();
        
        expect(
          () => db.createDatabase(
            testDirectory,
            '',
            TableType.balance,
            ['measurement1'],
            ['resource1'],
          ),
          throwsA(predicate((e) => e is ArgumentError && e.message.contains('Название базы данных'))),
        );
      });
      
      test('Create database with empty measurements', () {
        final db = Database();
        
        expect(
          () => db.createDatabase(
            testDirectory,
            'test_db',
            TableType.balance,
            [],
            ['resource1'],
          ),
          throwsA(predicate((e) => e is ArgumentError && e.message.contains('Список измерений'))),
        );
      });
      
      test('Create database with empty resources', () {
        final db = Database();
        
        expect(
          () => db.createDatabase(
            testDirectory,
            'test_db',
            TableType.balance,
            ['measurement1'],
            [],
          ),
          throwsA(predicate((e) => e is ArgumentError && e.message.contains('Список ресурсов'))),
        );
      });
      
      test('Create database that already exists', () async {
        final db = Database();
        
        // Сначала создаем базу данных
        await db.createDatabase(
          testDirectory,
          'existing_db',
          TableType.balance,
          ['measurement1'],
          ['resource1'],
        );
        
        // Пытаемся создать базу данных с тем же именем - должно вызвать ошибку
        expect(
          () => db.createDatabase(
            testDirectory,
            'existing_db',
            TableType.balance,
            ['measurement1'],
            ['resource1'],
          ),
          throwsA(predicate((e) => e is StateError && e.message.contains('уже существует'))),
        );
      });
    });
  });
}
