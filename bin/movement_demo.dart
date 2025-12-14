import 'dart:io';
import 'dart:math';
import 'package:hc_db/hc_db.dart';

void main() async {
  // Создаем директорию для базы данных если её нет
  final demoDir = Directory('./db');
  if (!await demoDir.exists()) {
    await demoDir.create(recursive: true);
  }
  
  // Проверяем, существует ли база данных
  final databasePath = './db/movement_demo';
  final dbDir = Directory(databasePath);
  
  late final Database db;
  
  if (await dbDir.exists()) {
    // Открываем существующую базу данных
    print('Открываем существующую базу данных...');
    db = await Database.open(
      directoryPath: './db',
      databaseName: 'movement_demo',
    );
  } else {
    // Создаем новую базу данных
    print('Создаем новую базу данных...');
    db = await Database.createDatabase(
      directoryPath: './db',
      databaseName: 'movement_demo',
      tableType: TableType.universal,
      measurements: ['product', 'region', 'category'],
      resources: ['quantity', 'amount', 'price'],
    );
  }

  // Создаем схему таблицы на основе параметров базы данных
  // Используем имя таблицы, соответствующее файлу данных
  final tableSchema = Table(
    name: 'movement_demo',
    type: db.tableType,
    measurements: db.measurements,
    resources: db.resources,
  );

  // Создаем таблицу движений
 final movementTable = MovementTable(db, tableSchema);
  
  // Выводим информацию о базе данных для отладки
  print('Тип таблицы: ${db.tableType}');
  print('Измерения: ${db.measurements}');
  print('Ресурсы: ${db.resources}');
  print('Путь к базе данных: ${db.databasePath}');
  print('Имя базы данных: ${db.databaseName}');
  
  // Запускаем консольное меню
  await runConsoleMenu(movementTable);
  
  await db.close();
}

Future<void> runConsoleMenu(MovementTable movementTable) async {
  bool exit = false;
  while (!exit) {
    print('\n=== Меню работы с движениями ===');
    print('1. Добавить случайную запись');
    print('2. Добавить 10 случайных записей');
    print('3. Добавить 10 случайных записей батчем');
    print('4. Добавить произвольное количество записей батчем');
    print('5. Прочитать все записи в виде таблицы');
    print('6. Выйти');
    print('Выберите опцию (1-6): ');
    
    String? input = stdin.readLineSync();
    int choice = int.tryParse(input ?? '') ?? 0;
    
    switch (choice) {
      case 1:
        await addRandomMovement(movementTable);
        break;
      case 2:
        await addTenRandomMovements(movementTable);
        break;
      case 3:
        await addTenRandomMovementsBatch(movementTable);
        break;
      case 4:
        await addArbitraryMovementsBatch(movementTable);
        break;
      case 5:
        await readAllMovements(movementTable);
        break;
      case 6:
        exit = true;
        print('Выход из программы...');
        break;
      default:
        print('Неверный выбор. Пожалуйста, выберите число от 1 до 6.');
    }
  }

}

Future<void> addRandomMovement(MovementTable movementTable) async {
  Movement movement = generateRandomMovement();
  await movementTable.insertMovement(movement);
  print('Добавлено движение: ${movement.movementId}');
}

Future<void> addTenRandomMovements(MovementTable movementTable) async {
  print('Добавляем 10 случайных записей по одной...');
  for (int i = 0; i < 10; i++) {
    Movement movement = generateRandomMovement();
    await movementTable.insertMovement(movement);
    print('Добавлено движение ${i + 1}/10: ${movement.movementId}');
  }
  print('Все 10 записей добавлены.');
}

Future<void> addTenRandomMovementsBatch(MovementTable movementTable) async {
  print('Добавляем 10 случайных записей батчем...');
  List<Movement> movements = [];
  for (int i = 0; i < 10; i++) {
    movements.add(generateRandomMovement());
  }
  
  await movementTable.insertMovementsBatch(movements);
  print('Все 10 записей добавлены батчем.');
}

Future<void> addArbitraryMovementsBatch(MovementTable movementTable) async {
  print('Введите количество записей для добавления: ');
  String? input = stdin.readLineSync();
  int count = int.tryParse(input ?? '') ?? 0;
  
  if (count <= 0) {
    print('Количество должно быть положительным числом.');
    return;
  }
  
  print('Добавляем $count случайных записей батчем...');
  List<Movement> movements = [];
  for (int i = 0; i < count; i++) {
    movements.add(generateRandomMovement());
  }
  
  await movementTable.insertMovementsBatch(movements);
  print('Все $count записей добавлены батчем.');
}

Future<void> readAllMovements(MovementTable movementTable) async {
  print('Пытаемся получить все движения...');
  List<Movement> movements = await movementTable.getMovements();
  
  print('Количество полученных движений: ${movements.length}');
  
  if (movements.isEmpty) {
    print('Нет записей для отображения.');
    return;
  }
  
  int pageSize = 25;
  int currentPage = 0;
  
  while (true) {
    int startIndex = currentPage * pageSize;
    int endIndex = (startIndex + pageSize < movements.length) ? startIndex + pageSize : movements.length;
    
    List<Movement> pageMovements = movements.sublist(startIndex, endIndex);
    
    print('\n=== Записи ${startIndex + 1} - ${endIndex} из ${movements.length} ===');
    // Заголовок таблицы
    print('${'ID'.padRight(15)} | ${'Timestamp'.padRight(20)} | ${'Product'.padRight(15)} | ${'Region'.padRight(12)} | ${'Category'.padRight(12)} | ${'Quantity'.padRight(12)} | ${'Amount'.padRight(12)} | ${'Direction'.padRight(12)}');
    print('-' * 130);
    
    // Данные таблицы
    for (Movement movement in pageMovements) {
      print(
        '${movement.movementId.padRight(15)} | '
        '${movement.timestamp.toIso8601String().substring(0, 19).padRight(20)} | '
        '${movement.measurements['product']?.padRight(15) ?? ''.padRight(15)} | '
        '${movement.measurements['region']?.padRight(12) ?? ''.padRight(12)} | '
        '${movement.measurements['category']?.padRight(12) ?? ''.padRight(12)} | '
        '${movement.resources['quantity']?.toString().padRight(12) ?? ''.padRight(12)} | '
        '${movement.resources['amount']?.toString().padRight(12) ?? ''.padRight(12)} | '
        '${movement.direction.toString().split('.').last.padRight(12)}'
      );
    }
    
    print('\nСтраница ${currentPage + 1} из ${(movements.length / pageSize).ceil()}');
    
    if (movements.length <= pageSize) {
      print('\nВсего записей: ${movements.length}');
      break;
    }
    
    print('\nУправление: [N] - следующие 25, [P] - предыдущие 25, [Q] - выход');
    String? input = stdin.readLineSync()?.toUpperCase();
    
    if (input == 'N' || input == 'NEXT') {
      if (endIndex < movements.length) {
        currentPage++;
      } else {
        print('Больше нет записей для отображения.');
      }
    } else if (input == 'P' || input == 'PREV' || input == 'PREVIOUS') {
      if (currentPage > 0) {
        currentPage--;
      } else {
        print('Это первая страница.');
      }
    } else if (input == 'Q' || input == 'QUIT' || input == 'EXIT') {
      break;
    } else {
      print('Неверная команда. Используйте N, P или Q.');
    }
  }
}

Movement generateRandomMovement() {
  Random random = Random();
  String id = 'M${DateTime.now().millisecondsSinceEpoch}${random.nextInt(100)}';
  
  List<String> products = ['Product A', 'Product B', 'Product C', 'Product D', 'Product E'];
  List<String> regions = ['North', 'South', 'East', 'West', 'Central'];
  List<String> categories = ['Electronics', 'Clothing', 'Food', 'Furniture', 'Books'];
  
  return Movement(
    movementId: id,
    timestamp: DateTime.now().subtract(Duration(minutes: random.nextInt(10000))),
    blockId: 'B${random.nextInt(1000000)}',
    transactionId: 'T${random.nextInt(1000000)}',
    measurements: {
      'product': products[random.nextInt(products.length)],
      'region': regions[random.nextInt(regions.length)],
      'category': categories[random.nextInt(categories.length)],
    },
    resources: {
      'quantity': BigInt.from(random.nextInt(1000) + 1),
      'amount': BigInt.from(random.nextInt(100000) + 100),
      'price': BigInt.from(random.nextInt(1000) + 10),
    },
    direction: random.nextBool() ? Direction.income : Direction.expense,
  );
}