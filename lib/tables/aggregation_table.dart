library;

import 'dart:async';
import '../core/database.dart';
import 'table_manager.dart';

// Структура агрегации
class Aggregation {
  final String aggregationId;
  final Map<String, String> measurements;
  final Map<String, String> resources;
  final BigInt currentValue;
  final DateTime lastUpdated;
  final int version;

  Aggregation({
    required this.aggregationId,
    required this.measurements,
    required this.resources,
    required this.currentValue,
    required this.lastUpdated,
    required this.version,
  });

  // Преобразование в мапу для хранения
  Map<String, dynamic> toMap() {
    return {
      'aggregationId': aggregationId,
      'measurements': measurements,
      'resources': resources,
      'currentValue': currentValue.toString(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }

  // Создание из мапы
  factory Aggregation.fromMap(Map<String, dynamic> map) {
    return Aggregation(
      aggregationId: map['aggregationId'],
      measurements: Map<String, String>.from(map['measurements']),
      resources: Map<String, String>.from(map['resources']),
      currentValue: BigInt.parse(map['currentValue']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
      version: map['version'],
    );
  }
}

// Таблица агрегаций - хранит итоговые значения
class AggregationTable {
  final Database database;
  final Table tableSchema;
  final Map<String, Aggregation> _aggregations = {};

  AggregationTable(this.database, this.tableSchema);

  // Вставка или обновление агрегации
  Future<void> upsertAggregation(Aggregation aggregation) async {
    // Валидация данных
    _validateAggregation(aggregation);
    
    // Обновление агрегации
    _aggregations[aggregation.aggregationId] = aggregation;
    
    print('Обновлена агрегация: ${aggregation.aggregationId}');
  }

  // Получение агрегации
  Aggregation? getAggregation(String id) {
    return _aggregations[id];
  }

  // Получение всех агрегаций
  Iterable<Aggregation> get aggregations => _aggregations.values;

  // Валидация агрегации
  void _validateAggregation(Aggregation aggregation) {
    // Проверка обязательных полей
    if (aggregation.aggregationId.isEmpty) {
      throw ArgumentError('aggregationId не может быть пустым');
    }
    
    // Проверка соответствия измерений схеме таблицы
    for (final measurement in aggregation.measurements.keys) {
      if (!tableSchema.measurements.contains(measurement)) {
        throw ArgumentError('Измерение $measurement не определено в схеме таблицы');
      }
    }
    
    // Проверка соответствия ресурсов схеме таблицы
    for (final resource in aggregation.resources.keys) {
      if (!tableSchema.resources.contains(resource)) {
        throw ArgumentError('Ресурс $resource не определен в схеме таблицы');
      }
    }
  }

  // Получение общего значения по фильтрам
  Future<BigInt> getTotalValue({
    Map<String, String>? measurementsFilter,
  }) async {
    BigInt total = BigInt.zero;
    
    for (final aggregation in _aggregations.values) {
      // Фильтрация по измерениям
      if (measurementsFilter != null) {
        bool match = true;
        for (final entry in measurementsFilter.entries) {
          if (aggregation.measurements[entry.key] != entry.value) {
            match = false;
            break;
          }
        }
        if (!match) continue;
      }
      
      total += aggregation.currentValue;
    }
    
    return total;
  }
}