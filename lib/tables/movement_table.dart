library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/database.dart';
import 'table_manager.dart';

/// Направление движения
enum Direction {
  income,   // Приход
  expense,  // Расход
}

/// Структура движения - представляет собой финансовую или материальную операцию
class Movement {
  /// Уникальный идентификатор движения
  final String movementId;
  
  /// Временная метка операции
  final DateTime timestamp;
  
  /// Идентификатор блока данных
  final String blockId;
  
  /// Идентификатор транзакции
  final String transactionId;
  
  /// Измерения (характеристики) движения
  final Map<String, String> measurements;
  
  /// Ресурсы (количественные показатели) движения
  final Map<String, BigInt> resources;
  
  /// Направление движения: приход или расход
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

  /// Преобразование в мапу для хранения
  Map<String, dynamic> toMap() {
    return {
      'movementId': movementId,
      'timestamp': timestamp.toIso8601String(),
      'blockId': blockId,
      'transactionId': transactionId,
      'measurements': measurements,
      'resources': resources.map((key, value) => MapEntry(key, value.toString())),
      'direction': direction.name, // Используем .name вместо .toString().split('.').last
    };
  }

  /// Создание из мапы
  factory Movement.fromMap(Map<String, dynamic> map) {
    return Movement(
      movementId: map['movementId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      blockId: map['blockId'] as String,
      transactionId: map['transactionId'] as String,
      measurements: Map<String, String>.from(map['measurements'] as Map),
      resources: (map['resources'] as Map<String, String>).map(
        (key, value) => MapEntry(key, BigInt.parse(value)),
      ),
      direction: _parseDirection(map['direction'] as String),
    );
  }

  /// Вспомогательный метод для безопасного парсинга Direction
  static Direction _parseDirection(String directionStr) {
    // Ищем соответствующее значение Direction по строке
    return Direction.values.firstWhere(
      (d) => d.name == directionStr || d.toString().split('.').last == directionStr,
      orElse: () => Direction.income,
    );
  }

  /// Получение Direction по строковому значению
  static Direction? tryParseDirection(String value) {
    try {
      return Direction.values.firstWhere(
        (d) => d.name == value || d.toString().split('.').last == value,
      );
    } on StateError {
      // Если не найдено подходящее значение, возвращаем null
      return null;
    }
  }
  
  /// Преобразование движения в строку для записи в файл
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
          values.add(direction.name); // Используем .name вместо .toString().split('.').last
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
  
  /// Создание движения из строки данных
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
          try {
            timestamp = DateTime.parse(value);
          } catch (e) {
            timestamp = DateTime.now();
          }
          break;
        case 'blockId':
          blockId = value;
          break;
        case 'transactionId':
          transactionId = value;
          break;
        case 'direction':
          direction = _parseDirection(value);
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
            // Проверяем, есть ли эта колонка в измерениях или ресурсах
            measurements[column] = value;
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

/// Класс для управления областью данных в файле
class DataAreaManager {
  final String databasePath;
  final String databaseName;
  final Table tableSchema;
  
  DataAreaManager({
    required this.databasePath,
    required this.databaseName,
    required this.tableSchema,
  });
  
  /// Получение пути к файлу движений
  String get movementsFilePath => '$databasePath/$databaseName.movements';
  
  /// Запись области данных в файл
  Future<void> writeDataArea(List<Movement> movements) async {
    File file = File(movementsFilePath);
    
    try {
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
      
      // Записываем область данных в файл с временным файлом для безопасности
      String tempFilePath = '${movementsFilePath}.tmp';
      File tempFile = File(tempFilePath);
      await tempFile.writeAsString(dataLines.join('\n'), mode: FileMode.writeOnly);
      
      // Атомарно заменяем основной файл
      await tempFile.rename(movementsFilePath);
    } catch (e) {
      throw Exception('Ошибка при записи области данных: $e');
    }
  }
  
  /// Чтение области данных из файла
  Future<List<Movement>> readDataArea() async {
    File file = File(movementsFilePath);
    
    if (!await file.exists()) {
      return [];
    }
    
    try {
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
    } catch (e) {
      throw Exception('Ошибка при чтении области данных: $e');
    }
  }
}

/// Таблица движений - логирование операций
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

  /// Вставка одного движения
  Future<void> insertMovement(Movement movement) async {
    try {
      // Валидация данных
      _validateMovement(movement);
      
      // Проверяем, что движения с таким ID еще не существует
      if (_movements.any((m) => m.movementId == movement.movementId)) {
        throw StateError('Движение с ID ${movement.movementId} уже существует');
      }
      
      // Добавление движения
      _movements.add(movement);
      
      print('Добавлено движение: ${movement.movementId}');
      
      // Записываем обновленные данные в файл
      await _dataAreaManager.writeDataArea(_movements);
    } catch (e) {
      throw Exception('Ошибка при вставке движения: $e');
    }
  }
  
  /// Вставка множества движений в одной транзакции
  Future<void> insertMovementsBatch(List<Movement> movements) async {
    try {
      // Проверяем на дубликаты внутри батча
      Set<String> batchIds = <String>{};
      for (final movement in movements) {
        if (batchIds.contains(movement.movementId)) {
          throw StateError('Обнаружен дубликат движения с ID ${movement.movementId} в батче');
        }
        batchIds.add(movement.movementId);
        
        // Проверяем, что движения с таким ID еще не существует
        if (_movements.any((m) => m.movementId == movement.movementId)) {
          throw StateError('Движение с ID ${movement.movementId} уже существует');
        }
      }
      
      // Валидация всех движений перед вставкой
      for (final movement in movements) {
        _validateMovement(movement);
      }
      
      // Добавление всех движений в память
      _movements.addAll(movements);
      
      print('Добавлено ${movements.length} движений в батче');
      
      // Записываем обновленные данные в файл единовременно
      await _dataAreaManager.writeDataArea(_movements);
    } catch (e) {
      throw Exception('Ошибка при вставке батча движений: $e');
    }
  }

  /// Получение движений по фильтрам
  Future<List<Movement>> getMovements({
    Map<String, String>? measurementsFilter,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
  }) async {
    try {
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
    } catch (e) {
      throw Exception('Ошибка при получении движений: $e');
    }
  }

  /// Валидация движения
  void _validateMovement(Movement movement) {
    // Проверка обязательных полей
    if (movement.movementId.isEmpty) {
      throw ArgumentError('movementId не может быть пустым');
    }
    
    if (movement.blockId.isEmpty) {
      throw ArgumentError('blockId не может быть пустым');
    }
    
    if (movement.transactionId.isEmpty) {
      throw ArgumentError('transactionId не может быть пустым');
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
    
    // Проверка, что измерения и ресурсы не пусты, если они определены в схеме
    for (final measurement in tableSchema.measurements) {
      if (!movement.measurements.containsKey(measurement)) {
        throw ArgumentError('Обязательное измерение $measurement отсутствует в движении');
      }
    }
    
    for (final resource in tableSchema.resources) {
      if (!movement.resources.containsKey(resource)) {
        throw ArgumentError('Обязательный ресурс $resource отсутствует в движении');
      }
    }
  }

  /// Получение количества движений
  int get count => _movements.length;
}