library;

import 'dart:async';
import '../core/database.dart';
import 'table_manager.dart';

// Тип периода
enum PeriodType {
  second,   // Секунда
  minute,   // Минута
  hour,     // Час
  day,      // День
  month,    // Месяц
  year,     // Год
}

// Структура оборота - хранит данные об оборотах за периоды
class Turnover {
  final String turnoverId;
  final DateTime timestamp;
  final PeriodType periodType;
  final Map<String, String> measurements;
  final Map<String, String> resources;
  final BigInt turnoverValue;
  final int count;
  final DateTime lastUpdated;

  Turnover({
    required this.turnoverId,
    required this.timestamp,
    required this.periodType,
    required this.measurements,
    required this.resources,
    required this.turnoverValue,
    required this.count,
    required this.lastUpdated,
  });

  // Преобразование в мапу для хранения
  Map<String, dynamic> toMap() {
    return {
      'turnoverId': turnoverId,
      'timestamp': timestamp.toIso8601String(),
      'periodType': periodType.toString().split('.').last,
      'measurements': measurements,
      'resources': resources,
      'turnoverValue': turnoverValue.toString(),
      'count': count,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Создание из мапы
  factory Turnover.fromMap(Map<String, dynamic> map) {
    return Turnover(
      turnoverId: map['turnoverId'],
      timestamp: DateTime.parse(map['timestamp']),
      periodType: PeriodType.values.firstWhere(
        (p) => p.toString().split('.').last == map['periodType'],
        orElse: () => PeriodType.second,
      ),
      measurements: Map<String, String>.from(map['measurements']),
      resources: Map<String, String>.from(map['resources']),
      turnoverValue: BigInt.parse(map['turnoverValue']),
      count: map['count'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}

// Таблица оборотов
class TurnoverTable {
  final Database database;
  final Table tableSchema;
  final Map<String, Turnover> _turnovers = {};

  TurnoverTable(this.database, this.tableSchema);

  // Вставка или обновление оборота
  Future<void> upsertTurnover(Turnover turnover) async {
    // Валидация данных
    _validateTurnover(turnover);
    
    // Обновление оборота
    _turnovers[turnover.turnoverId] = turnover;
    
    print('Обновлен оборот: ${turnover.turnoverId}');
  }

  // Получение оборота
  Turnover? getTurnover(String id) {
    return _turnovers[id];
  }

  // Получение всех оборотов
  Iterable<Turnover> get turnovers => _turnovers.values;

  // Валидация оборота
  void _validateTurnover(Turnover turnover) {
    // Проверка обязательных полей
    if (turnover.turnoverId.isEmpty) {
      throw ArgumentError('turnoverId не может быть пустым');
    }
    
    // Проверка соответствия измерений схеме таблицы
    for (final measurement in turnover.measurements.keys) {
      if (!tableSchema.measurements.contains(measurement)) {
        throw ArgumentError('Измерение $measurement не определено в схеме таблицы');
      }
    }
    
    // Проверка соответствия ресурсов схеме таблицы
    for (final resource in turnover.resources.keys) {
      if (!tableSchema.resources.contains(resource)) {
        throw ArgumentError('Ресурс $resource не определен в схеме таблицы');
      }
    }
  }

  // Получение оборотов по фильтрам
  Future<List<Turnover>> getTurnovers({
    Map<String, String>? measurementsFilter,
    PeriodType? periodType,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
  }) async {
    var result = _turnovers.values.where((turnover) {
      // Фильтрация по измерениям
      if (measurementsFilter != null) {
        bool match = true;
        for (final entry in measurementsFilter.entries) {
          if (turnover.measurements[entry.key] != entry.value) {
            match = false;
            break;
          }
        }
        if (!match) return false;
      }
      
      // Фильтрация по типу периода
      if (periodType != null && turnover.periodType != periodType) {
        return false;
      }
      
      // Фильтрация по времени
      if (fromTime != null && turnover.timestamp.isBefore(fromTime)) {
        return false;
      }
      
      if (toTime != null && turnover.timestamp.isAfter(toTime)) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Сортировка по времени (по убыванию)
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Ограничение количества результатов
    if (limit != null && result.length > limit) {
      result = result.sublist(0, limit);
    }
    
    return result;
  }
}