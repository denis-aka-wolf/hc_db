
library;

import 'dart:async';
import '../core/database.dart';
import '../tables/table_manager.dart';
import '../tables/movement_table.dart';

// Движок агрегаций - отвечает за автоматическое вычисление итоговых значений
class AggregationEngine {
  final Database database;
  final TableManager tableManager;

  AggregationEngine(this.database, this.tableManager);

  // Обновление агрегаций на основе новых движений
  Future<void> updateAggregations(String tableName, Movement movement) async {
    final table = tableManager.getTable(tableName);
    if (table == null) {
      throw StateError('Таблица $tableName не существует');
    }

    // В данном примере просто выводим информацию о движении
    print('Обновление агрегаций для таблицы $tableName на основе движения ${movement.movementId}');
    
    // Тут будет логика обновления таблицы агрегаций
    // на основе данных из движения
    
    // Например, можно было бы:
    // 1. Найти существующую агрегацию для данного измерения
    // 2. Обновить значение агрегации
    // 3. Увеличить версию данных
    // 4. Сохранить изменения в таблице агрегаций
    
    // Сейчас просто выводим сообщение о том, что агрегация была обновлена
  }

  // Ручной пересчет агрегаций
  Future<void> recalculateAggregations(String tableName) async {
    final table = tableManager.getTable(tableName);
    if (table == null) {
      throw StateError('Таблица $tableName не существует');
    }

    print('Ручной пересчет агрегаций для таблицы $tableName');
    
    // Тут будет логика пересчета всех агрегаций
    // для указанной таблицы на основе всех движений
  }

  // Получение итогового значения по таблице
  Future<BigInt> getTotalValue(String tableName, {Map<String, String>? measurementsFilter}) async {
    final table = tableManager.getTable(tableName);
    if (table == null) {
      throw StateError('Таблица $tableName не существует');
    }

    // Тут будет получение итогового значения
    // из таблицы агрегаций с учетом фильтров
    
    print('Получение итогового значения для таблицы $tableName');
    
    // Для демонстрации возвращаем ноль
    return BigInt.zero;
  }
}