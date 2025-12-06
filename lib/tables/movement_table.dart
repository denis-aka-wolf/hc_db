library;

import 'dart:async';
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
}

// Таблица движений - логирование операций
class MovementTable {
  final Database database;
  final Table tableSchema;
  final List<Movement> _movements = [];

  MovementTable(this.database, this.tableSchema);

  // Вставка движения
  Future<void> insertMovement(Movement movement) async {
    // Валидация данных
    _validateMovement(movement);
    
    // Добавление движения
    _movements.add(movement);
    
    print('Добавлено движение: ${movement.movementId}');
  }

  // Получение движений по фильтрам
  Future<List<Movement>> getMovements({
    Map<String, String>? measurementsFilter,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
  }) async {
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