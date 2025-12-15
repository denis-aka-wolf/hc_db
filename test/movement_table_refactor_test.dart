import 'dart:io';
import 'package:test/test.dart';
import '../lib/tables/movement_table.dart';
import '../lib/core/database.dart';
import '../lib/tables/table_manager.dart';

void main() {
  group('MovementTable Refactor Tests', () {
    late Database database;
    late Table tableSchema;
    late MovementTable movementTable;
    late String testDir;

    setUp(() async {
      testDir = './db/test_data_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDir).create(recursive: true);
      
      // Создаем тестовую базу данных
      database = await Database.createDatabase(
        directoryPath: testDir,
        databaseName: 'test_db',
        tableType: TableType.universal,
        measurements: ['product', 'location'],
        resources: ['quantity', 'price'],
      );
      
      // Создаем тестовую схему таблицы
      tableSchema = Table(
        name: 'test_table',
        type: TableType.universal,
        measurements: ['product', 'location'],
        resources: ['quantity', 'price'],
      );
      
      movementTable = MovementTable(database, tableSchema);
    });

    tearDown(() async {
      await database.close();
      await Directory(testDir).delete(recursive: true);
    });

    test('Movement creation and serialization', () {
      final movement = Movement(
        movementId: 'test_id_1',
        timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        blockId: 'block_1',
        transactionId: 'trans_1',
        measurements: {'product': 'apple', 'location': 'warehouse_1'},
        resources: {'quantity': BigInt.from(100), 'price': BigInt.from(500)},
        direction: Direction.income,
      );

      // Проверяем сериализацию
      final map = movement.toMap();
      expect(map['movementId'], 'test_id_1');
      expect(map['direction'], 'income');

      // Проверяем десериализацию
      final fromMap = Movement.fromMap(map);
      expect(fromMap.movementId, 'test_id_1');
      expect(fromMap.direction, Direction.income);
      expect(fromMap.resources['quantity'], BigInt.from(100));
    });

    test('Direction parsing', () {
      // Тестируем безопасный парсинг Direction
      expect(Movement.tryParseDirection('income'), Direction.income);
      expect(Movement.tryParseDirection('expense'), Direction.expense);
      expect(Movement.tryParseDirection('invalid'), null);
    });

    test('MovementTable operations', () async {
      final movement = Movement(
        movementId: 'test_id_6',
        timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        blockId: 'block_1',
        transactionId: 'trans_3',
        measurements: {'product': 'orange', 'location': 'warehouse_1'},
        resources: {'quantity': BigInt.from(150), 'price': BigInt.from(400)},
        direction: Direction.income,
      );

      // Вставляем движение
      await movementTable.insertMovement(movement);
      
      // Проверяем, что оно добавилось
      expect(movementTable.count, 1);
      
      // Получаем движение обратно
      final retrieved = await movementTable.getMovements();
      expect(retrieved.length, 1);
      expect(retrieved[0].movementId, 'test_id_6');
    });

    test('MovementTable batch operations', () async {
      final movements = [
        Movement(
          movementId: 'batch_id_1',
          timestamp: DateTime(2023, 1, 1, 12, 0, 0),
          blockId: 'block_1',
          transactionId: 'trans_4',
          measurements: {'product': 'apple', 'location': 'warehouse_1'},
          resources: {'quantity': BigInt.from(100), 'price': BigInt.from(500)},
          direction: Direction.income,
        ),
        Movement(
          movementId: 'batch_id_2',
          timestamp: DateTime(2023, 1, 1, 13, 0, 0),
          blockId: 'block_1',
          transactionId: 'trans_5',
          measurements: {'product': 'banana', 'location': 'warehouse_2'},
          resources: {'quantity': BigInt.from(200), 'price': BigInt.from(300)},
          direction: Direction.expense,
        ),
      ];

      // Вставляем батч движений
      await movementTable.insertMovementsBatch(movements);
      
      // Проверяем, что они добавились
      expect(movementTable.count, 2);
      
      // Получаем движения обратно
      final retrieved = await movementTable.getMovements();
      expect(retrieved.length, 2);
    });

    test('MovementTable filtering', () async {
      final movements = [
        Movement(
          movementId: 'filter_id_1',
          timestamp: DateTime(2023, 1, 1, 10, 0, 0),
          blockId: 'block_1',
          transactionId: 'trans_6',
          measurements: {'product': 'apple', 'location': 'warehouse_1'},
          resources: {'quantity': BigInt.from(100), 'price': BigInt.from(500)},
          direction: Direction.income,
        ),
        Movement(
          movementId: 'filter_id_2',
          timestamp: DateTime(2023, 1, 1, 14, 0, 0),
          blockId: 'block_1',
          transactionId: 'trans_7',
          measurements: {'product': 'banana', 'location': 'warehouse_1'},
          resources: {'quantity': BigInt.from(200), 'price': BigInt.from(300)},
          direction: Direction.expense,
        ),
      ];

      await movementTable.insertMovementsBatch(movements);

      // Тестируем фильтрацию по измерениям
      final filteredByMeasurement = await movementTable.getMovements(
        measurementsFilter: {'location': 'warehouse_1'},
      );
      expect(filteredByMeasurement.length, 2);

      // Тестируем фильтрацию по времени
      final filteredByTime = await movementTable.getMovements(
        fromTime: DateTime(2023, 1, 1, 12, 0, 0),
        toTime: DateTime(2023, 1, 1, 15, 0, 0),
      );
      expect(filteredByTime.length, 1);
      expect(filteredByTime[0].movementId, 'filter_id_2');
    });

    test('Movement validation and duplicate check', () async {
      final movement = Movement(
        movementId: 'unique_id',
        timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        blockId: 'block_1',
        transactionId: 'trans_8',
        measurements: {'product': 'apple', 'location': 'warehouse_1'},
        resources: {'quantity': BigInt.from(100), 'price': BigInt.from(500)},
        direction: Direction.income,
      );

      // Вставляем движение
      await movementTable.insertMovement(movement);
      
      // Пытаемся вставить движение с тем же ID - должно вызвать ошибку
      expect(() => movementTable.insertMovement(movement), throwsA(isA<Exception>()));
    });
  });
}