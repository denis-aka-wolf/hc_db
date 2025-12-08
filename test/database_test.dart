import 'package:test/test.dart';
import 'package:hc_db/hc_db.dart';

void main() {
  group('Database Tests', () {
    test('Database creation with parameters', () async {
      // Тестируем создание базы данных с параметрами
      final db = await Database.createDatabase(
        directoryPath: 'test_dir',
        databaseName: 'test_db',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, 'test_dir');
      expect(db.databaseName, 'test_db');
      expect(db.tableType, TableType.balance);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });

    test('Database initialization', () async {
      final db = await Database.createDatabase(
        directoryPath: '.',
        databaseName: 'test_db',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      await db.init();
      // Проверяем, что база данных инициализирована без ошибок
      expect(true, true);
    });
  });
}