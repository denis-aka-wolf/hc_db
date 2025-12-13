library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/database.dart';
import 'table_manager.dart';

// Направление движения
enum Direction {
  income,   // Приход
  expense,  // Расход
}

// Структура движения
class Movement {
  final String movementId;
  final DateTime timestamp;
  final String blockId;
  final String transactionId;
  final Map<String, String> measurements;
  final Map<String, BigInt> resources;
  final Direction direction;

  Movement({
    required this.movementId,
    required this.timestamp,
    required this.blockId,
    required this.transactionId,
    required this.measurements,
    required this.resources,
    required this.direction,
  });

  // Преобразование в мапу для хранения
  Map<String, dynamic> toMap() {
    return {
      'movementId': movementId,
      'timestamp': timestamp.toIso8601String(),
      'blockId': blockId,
      'transactionId': transactionId,
      'measurements': measurements,
      'resources': resources.map((key, value) => MapEntry(key, value.toString())),
      'direction': direction.toString().split('.').last,
    };
  }

  // Создание из мапы
  factory Movement.fromMap(Map<String, dynamic> map) {
    return Movement(
      movementId: map['movementId'],
      timestamp: DateTime.parse(map['timestamp']),
      blockId: map['blockId'],
      transactionId: map['transactionId'],
      measurements: Map<String, String>.from(map['measurements']),
      resources: Map<String, String>.from(map['resources']).map(
        (key, value) => MapEntry(key, BigInt.parse(value)),
      ),
      direction: Direction.values.firstWhere(
        (d) => d.toString().split('.').last == map['direction'],
        orElse: () => Direction.income,
      ),
    );
  }
  
  // Преобразование движения в строку для записи в файл
  String toDataAreaFormat(List<String> columnOrder) {
    List<String> values = [];
    
    // Следуем порядку колонок
    for (String column in columnOrder) {
      switch (column) {
        case 'movementId':
          values.add(movementId);
          break;
        case 'timestamp':
          values.add(timestamp.toIso8601String());
          break;
        case 'blockId':
          values.add(blockId);
          break;
        case 'transactionId':
          values.add(transactionId);
          break;
        case 'direction':
          values.add(direction.toString().split('.').last);
          break;
        default:
          // Проверяем, является ли колонка измерением
          if (measurements.containsKey(column)) {
            values.add(measurements[column] ?? '');
          }
          // Проверяем, является ли колонка ресурсом
          else if (resources.containsKey(column)) {
            values.add(resources[column]?.toString() ?? '');
          }
          else {
            values.add('');
          }
          break;
      }
    }
    
    // Используем символ разделителя колонок '|'
    return values.join('|');
  }
  
  // Создание движения из строки данных
  static Movement fromDataAreaFormat(String dataLine, List<String> columnOrder) {
    List<String> values = dataLine.split('|');
    
    // Создаем мапы для измерений и ресурсов
    Map<String, String> measurements = {};
    Map<String, BigInt> resources = {};
    String? movementId, blockId, transactionId;
    DateTime? timestamp;
    Direction? direction;
    
    // Парсим значения в соответствии с порядком колонок
    for (int i = 0; i < columnOrder.length && i < values.length; i++) {
      String column = columnOrder[i];
      String value = values[i];
      
      switch (column) {
        case 'movementId':
          movementId = value;
          break;
        case 'timestamp':
          timestamp = DateTime.parse(value);
          break;
        case 'blockId':
          blockId = value;
          break;
        case 'transactionId':
          transactionId = value;
          break;
        case 'direction':
          direction = Direction.values.firstWhere(
            (d) => d.toString().split('.').last == value,
            orElse: () => Direction.income,
          );
          break;
        default:
          // Проверяем, является ли колонка измерением
          if (column.startsWith('measurement_')) {
            measurements[column] = value;
          }
          // Проверяем, является ли колонка ресурсом
          else if (column.startsWith('resource_')) {
            resources[column] = BigInt.tryParse(value) ?? BigInt.zero;
          }
          else {
            // Если не начинается с префиксов, определяем по схеме
            // (предполагается, что схема будет доступна при парсинге)
          }
          break;
      }
    }
    
    return Movement(
      movementId: movementId ?? '',
      timestamp: timestamp ?? DateTime.now(),
      blockId: blockId ?? '',
      transactionId: transactionId ?? '',
      measurements: measurements,
      resources: resources,
      direction: direction ?? Direction.income,
    );
  }
}

// Класс для управления областью данных в файле
class DataAreaManager {
  final String databasePath;
  final String databaseName;
  final Table tableSchema;
  
  DataAreaManager({
    required this.databasePath,
    required this.databaseName,
    required this.tableSchema,
  });
  
  // Получение пути к файлу движений
  String get movementsFilePath => '$databasePath/$databaseName.movements';
  
  // Запись области данных в файл
  Future<void> writeDataArea(List<Movement> movements) async {
    File file = File(movementsFilePath);
    
    // Формируем порядок колонок: сначала системные, потом измерения, затем ресурсы
    List<String> columnOrder = [
      'movementId',
      'timestamp',
      'blockId',
      'transactionId',
      'direction',
      ...tableSchema.measurements,
      ...tableSchema.resources,
    ];
    
    // Формируем содержимое области данных
    List<String> dataLines = [
      '// DATABASE DATA AREA',
      // Записываем порядок колонок
      'columns: ${columnOrder.join('|')}',
    ];
    
    // Добавляем сами данные
    for (Movement movement in movements) {
      dataLines.add(movement.toDataAreaFormat(columnOrder));
    }
    
    dataLines.add('// END DATA AREA');
    
    // Записываем область данных в файл
    await file.writeAsString(dataLines.join('\n'), mode: FileMode.writeOnly);
  }
  
  // Чтение области данных из файла
  Future<List<Movement>> readDataArea() async {
    File file = File(movementsFilePath);
    
    if (!await file.exists()) {
      return [];
    }
    
    String content = await file.readAsString();
    List<String> lines = LineSplitter.split(content).toList();
    
    // Находим начало и конец области данных
    int startIndex = -1;
    int endIndex = -1;
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim() == '// DATABASE DATA AREA') {
        startIndex = i;
      } else if (lines[i].trim() == '// END DATA AREA') {
        endIndex = i;
        break;
      }
    }
    
    // Если область данных не найдена, возвращаем пустой список
    if (startIndex == -1 || endIndex == -1) {
      return [];
    }
    
    // Извлекаем строки данных
    List<String> dataLines = lines.sublist(startIndex + 1, endIndex);
    
    if (dataLines.isEmpty) {
      return [];
    }
    
    // Первая строка содержит описание колонок
    List<String> columnOrder = [];
    if (dataLines[0].startsWith('columns: ')) {
      String columnsLine = dataLines[0].substring(9); // убираем 'columns: '
      columnOrder = columnsLine.split('|');
      dataLines = dataLines.sublist(1); // удаляем строку с описанием колонок
    } else {
      // Если не нашли строку с описанием колонок, используем стандартный порядок
      columnOrder = [
        'movementId',
        'timestamp',
        'blockId',
        'transactionId',
        'direction',
        ...tableSchema.measurements,
        ...tableSchema.resources,
      ];
    }
    
    // Парсим данные
    List<Movement> movements = [];
    for (String dataLine in dataLines) {
      if (dataLine.trim().isNotEmpty) {
        Movement movement = Movement.fromDataAreaFormat(dataLine, columnOrder);
        movements.add(movement);
      }
    }
    
    return movements;
  }
}

// Таблица движений - логирование операций
class MovementTable {
  final Database database;
  final Table tableSchema;
  final List<Movement> _movements = [];
  late DataAreaManager _dataAreaManager;

  MovementTable(this.database, this.tableSchema) {
    // Инициализируем DataAreaManager
    _dataAreaManager = DataAreaManager(
      databasePath: database.databasePath,
      databaseName: database.databaseName,
      tableSchema: tableSchema,
    );
  }

  // Вставка одного движения
  Future<void> insertMovement(Movement movement) async {
    // Валидация данных
    _validateMovement(movement);
    
    // Добавление движения
    _movements.add(movement);
    
    print('Добавлено движение: ${movement.movementId}');
    
    // Записываем обновленные данные в файл
    await _dataAreaManager.writeDataArea(_movements);
  }
  
  // Вставка множества движений в одной транзакции
  Future<void> insertMovementsBatch(List<Movement> movements) async {
    // Валидация всех движений перед вставкой
    for (final movement in movements) {
      _validateMovement(movement);
    }
    
    // Добавление всех движений в память
    _movements.addAll(movements);
    
    print('Добавлено ${movements.length} движений в батче');
    
    // Записываем обновленные данные в файл единовременно
    await _dataAreaManager.writeDataArea(_movements);
  }

  // Получение движений по фильтрам
  Future<List<Movement>> getMovements({
    Map<String, String>? measurementsFilter,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
  }) async {
    // Сначала читаем данные из файла, чтобы обеспечить актуальность
    List<Movement> movementsFromFile = await _dataAreaManager.readDataArea();
    
    // Объединяем с данными в памяти, если они различаются
    if (movementsFromFile.length != _movements.length) {
      _movements.clear();
      _movements.addAll(movementsFromFile);
    }
    
    var result = _movements.where((movement) {
      // Фильтрация по измерениям
      if (measurementsFilter != null) {
        for (final entry in measurementsFilter.entries) {
          if (movement.measurements[entry.key] != entry.value) {
            return false;
          }
        }
      }
      
      // Фильтрация по времени
      if (fromTime != null && movement.timestamp.isBefore(fromTime)) {
        return false;
      }
      
      if (toTime != null && movement.timestamp.isAfter(toTime)) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Ограничение количества результатов
    if (limit != null && result.length > limit) {
      result = result.sublist(0, limit);
    }
    
    return result;
  }

  // Валидация движения
  void _validateMovement(Movement movement) {
    // Проверка обязательных полей
    if (movement.movementId.isEmpty) {
      throw ArgumentError('movementId не может быть пустым');
    }
    
    // Проверка соответствия измерений схеме таблицы
    for (final measurement in movement.measurements.keys) {
      if (!tableSchema.measurements.contains(measurement)) {
        throw ArgumentError('Измерение $measurement не определено в схеме таблицы');
      }
    }
    
    // Проверка соответствия ресурсов схеме таблицы
    for (final resource in movement.resources.keys) {
      if (!tableSchema.resources.contains(resource)) {
        throw ArgumentError('Ресурс $resource не определен в схеме таблицы');
      }
    }
  }

  // Получение количества движений
  int get count => _movements.length;
}