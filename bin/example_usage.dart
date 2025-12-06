/// Пример использования библиотеки hc_db
///
/// Этот файл демонстрирует основные возможности базы данных hc_db,
/// включая создание таблиц, добавление данных, выполнение запросов
/// и использование движков агрегации и индексации.

import 'package:hc_db/hc_db.dart';

void main() async {
  // Создаем экземпляр базы данных
  final db = Database();
  
  // Инициализируем базу данных
  await db.init();
  
  print('=== Пример использования hc_db ===\n');
  
  // Создаем таблицы
  print('1. Создание таблиц:');
  
  // Создаем схемы таблиц
  final movementTableSchema = Table(
    name: 'movement_table',
    type: TableType.universal,
    measurements: ['product_id', 'date', 'type'],
    resources: ['quantity'],
  );
  
  final turnoverTableSchema = Table(
    name: 'turnover_table',
    type: TableType.turnover,
    measurements: ['product_id', 'date'],
    resources: ['amount'],
  );
  
  // Создаем таблицы
  final movementTable = MovementTable(db, movementTableSchema);
  final turnoverTable = TurnoverTable(db, turnoverTableSchema);
  
  print('   - Таблица движения создана');
  print('   - Таблица оборота создана\n');
  
  // Добавляем данные в таблицы
  print('2. Добавление данных:');
  
  // Добавляем записи в таблицу движения
  final movement1 = Movement(
    movementId: 'm1',
    timestamp: DateTime.parse('2023-01-15'),
    blockId: 'block1',
    transactionId: 'tx1',
    measurements: {'product_id': 'P001', 'date': '2023-01-15', 'type': 'in'},
    resources: {'quantity': BigInt.from(10)},
    direction: Direction.income,
  );
  
  final movement2 = Movement(
    movementId: 'm2',
    timestamp: DateTime.parse('2023-01-16'),
    blockId: 'block2',
    transactionId: 'tx2',
    measurements: {'product_id': 'P001', 'date': '2023-01-16', 'type': 'out'},
    resources: {'quantity': BigInt.from(5)},
    direction: Direction.expense,
  );
  
  final movement3 = Movement(
    movementId: 'm3',
    timestamp: DateTime.parse('2023-01-17'),
    blockId: 'block3',
    transactionId: 'tx3',
    measurements: {'product_id': 'P002', 'date': '2023-01-17', 'type': 'in'},
    resources: {'quantity': BigInt.from(15)},
    direction: Direction.income,
  );
  
  await movementTable.insertMovement(movement1);
  await movementTable.insertMovement(movement2);
  await movementTable.insertMovement(movement3);
  
  print('   - Добавлены записи в таблицу движения');
  
  // Добавляем записи в таблицу оборота
  final turnover1 = Turnover(
    turnoverId: 't1',
    timestamp: DateTime.parse('2023-01-15'),
    periodType: PeriodType.day,
    measurements: {'product_id': 'P001', 'date': '2023-01-15'},
    resources: {'amount': '100.0'},
    turnoverValue: BigInt.from(100),
    count: 1,
    lastUpdated: DateTime.now(),
  );
  
  final turnover2 = Turnover(
    turnoverId: 't2',
    timestamp: DateTime.parse('2023-01-16'),
    periodType: PeriodType.day,
    measurements: {'product_id': 'P001', 'date': '2023-01-16'},
    resources: {'amount': '50.0'},
    turnoverValue: BigInt.from(50),
    count: 1,
    lastUpdated: DateTime.now(),
  );
  
  await turnoverTable.upsertTurnover(turnover1);
  await turnoverTable.upsertTurnover(turnover2);
  
  print('   - Добавлены записи в таблицу оборота\n');
  
  // Выполняем запросы к данным
  print('3. Выполнение запросов:');
  
  // Получаем все записи из таблицы движения
  final movements = await movementTable.getMovements();
  print('   - Все записи из таблицы движения:');
  for (var movement in movements) {
    print('     ${movement.movementId}: ${movement.measurements['product_id']} - ${movement.resources['quantity']} шт.');
  }
  
  // Получаем все записи из таблицы оборота
  final turnovers = await turnoverTable.getTurnovers();
  print('   - Все записи из таблицы оборота:');
  for (var turnover in turnovers) {
    print('     ${turnover.turnoverId}: ${turnover.measurements['product_id']} - ${turnover.resources['amount']} руб.');
  }
  
  print('\n=== Пример использования завершен ===');
}