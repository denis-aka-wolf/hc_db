import 'package:test/test.dart';
import 'package:hc_db/hc_db.dart';

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
  });
}
