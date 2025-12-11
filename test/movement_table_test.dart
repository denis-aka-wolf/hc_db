import 'dart:io';
import 'package:hc_db/hc_db.dart';
import 'package:test/test.dart';

void main() async {
  final testDir = './db';
  final dbName = 'movement_test';

  setUp(() async {
    // Создаем директорию для тестовой базы данных
    final dbDir = Directory(testDir);
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
  });

 tearDown(() async {
    // Удаляем тестовую базу данных после каждого теста
    final dbDir = Directory(testDir);
    if (await dbDir.exists()) {
      await dbDir.delete(recursive: true);
    }
  });

  test('DataArea functionality test', () async {
    // Создаем базу данных
    final db = await Database.createDatabase(
      directoryPath: testDir,
      databaseName: dbName,
      tableType: TableType.universal,
      measurements: ['product', 'region'],
      resources: ['quantity', 'amount'],
    );

    // Создаем таблицу движений
    final tableSchema = Table(
      name: 'movements',
      type: TableType.universal,
      measurements: ['product', 'region'],
      resources: ['quantity', 'amount'],
    );
    
    final movementTable = MovementTable(db, tableSchema);

    // Создаем и добавляем движения
    final movement1 = Movement(
      movementId: 'M001',
      timestamp: DateTime(2023, 1, 1, 10, 0),
      blockId: 'B001',
      transactionId: 'T001',
      measurements: {
        'product': 'Product A',
        'region': 'Region 1',
      },
      resources: {
        'quantity': BigInt.from(100),
        'amount': BigInt.from(1000),
      },
      direction: Direction.income,
    );

    final movement2 = Movement(
      movementId: 'M002',
      timestamp: DateTime(2023, 1, 1, 11, 0),
      blockId: 'B002',
      transactionId: 'T002',
      measurements: {
        'product': 'Product B',
        'region': 'Region 2',
      },
      resources: {
        'quantity': BigInt.from(20),
        'amount': BigInt.from(2000),
      },
      direction: Direction.expense,
    );

    // Добавляем движения в таблицу
    await movementTable.insertMovement(movement1);
    await movementTable.insertMovement(movement2);

    // Проверяем, что движения добавлены в память
    expect(movementTable.count, 2);

    // Проверяем, что файл движений существует
    final movementsFile = File('$testDir/$dbName/$dbName.movements');
    expect(await movementsFile.exists(), true);

    // Читаем содержимое файла и проверяем структуру DataArea
    final content = await movementsFile.readAsString();
    expect(content.contains('// DATABASE DATA AREA'), true);
    expect(content.contains('// END DATA AREA'), true);
    expect(content.contains('M001'), true);
    expect(content.contains('M002'), true);

    // Проверяем, что можем прочитать движения из файла
    final readMovements = await movementTable.getMovements();
    expect(readMovements.length, 2);

    // Проверяем, что данные корректно восстановлены
    final firstMovement = readMovements.firstWhere((m) => m.movementId == 'M001');
    expect(firstMovement.timestamp, DateTime(2023, 1, 1, 10, 0));
    expect(firstMovement.measurements['product'], 'Product A');
    expect(firstMovement.resources['quantity'], BigInt.from(100));
    expect(firstMovement.direction, Direction.income);

    final secondMovement = readMovements.firstWhere((m) => m.movementId == 'M002');
    expect(secondMovement.timestamp, DateTime(2023, 1, 1, 11, 0));
    expect(secondMovement.measurements['product'], 'Product B');
    expect(secondMovement.resources['quantity'], BigInt.from(20));
    expect(secondMovement.direction, Direction.expense);

    // Проверяем фильтрацию
    final filteredMovements = await movementTable.getMovements(
      measurementsFilter: {'product': 'Product A'},
    );
    expect(filteredMovements.length, 1);
    expect(filteredMovements.first.movementId, 'M001');

    await db.close();
  });
}