library;

import 'dart:async';
import '../core/database.dart';
import '../tables/table_manager.dart';
import '../tables/turnover_table.dart';
import '../engines/aggregation_engine.dart';
import '../engines/indexing_engine.dart';

// Типы запросов
enum QueryType {
  movements,    // Движения
  aggregations, // Агрегации
  turnovers,    // Обороты
}

// Параметры запроса
class QueryParams {
  final QueryType type;
  final String tableName;
  final Map<String, String>? filters;
  final DateTime? fromTime;
  final DateTime? toTime;
  final int? limit;
  final String? period;

  QueryParams({
    required this.type,
    required this.tableName,
    this.filters,
    this.fromTime,
    this.toTime,
    this.limit,
    this.period,
  });
}

// Результат запроса
class QueryResult {
  final QueryType type;
  final dynamic data;
  final int count;

  QueryResult({
    required this.type,
    required this.data,
    required this.count,
  });
}

// Интерфейс запросов - предоставляет API для работы с данными
class QueryInterface {
  final Database database;
  final TableManager tableManager;
  final AggregationEngine aggregationEngine;
  final IndexingEngine indexingEngine;

  QueryInterface(
    this.database,
    this.tableManager,
    this.aggregationEngine,
    this.indexingEngine,
  );

  // Выполнение запроса к базе данных
  Future<QueryResult> execute(QueryParams params) async {
    switch (params.type) {
      case QueryType.movements:
        return await _executeMovementsQuery(params);
      case QueryType.aggregations:
        return await _executeAggregationsQuery(params);
      case QueryType.turnovers:
        return await _executeTurnoversQuery(params);
    }
  }

  // Выполнение запроса на движения
  Future<QueryResult> _executeMovementsQuery(QueryParams params) async {
    // Тут будет логика получения движений
    print('Выполнение запроса на движения в таблице ${params.tableName}');
    
    // Для демонстрации возвращаем пустой список
    return QueryResult(
      type: QueryType.movements,
      data: [],
      count: 0,
    );
  }

  // Выполнение запроса на агрегации
  Future<QueryResult> _executeAggregationsQuery(QueryParams params) async {
    // В реальной реализации здесь будет логика получения агрегаций
    print('Выполнение запроса на агрегации в таблице ${params.tableName}');
    
    // Для демонстрации возвращаем пустой список
    return QueryResult(
      type: QueryType.aggregations,
      data: [],
      count: 0,
    );
  }

  // Выполнение запроса на обороты
  Future<QueryResult> _executeTurnoversQuery(QueryParams params) async {
    // В реальной реализации здесь будет логика получения оборотов
    print('Выполнение запроса на обороты в таблице ${params.tableName}');
    
    // Для демонстрации возвращаем пустой список
    return QueryResult(
      type: QueryType.turnovers,
      data: [],
      count: 0,
    );
  }

  // Получение итогового значения
  Future<BigInt> getTotalValue(String tableName, {Map<String, String>? filters}) async {
    return await aggregationEngine.getTotalValue(tableName, measurementsFilter: filters);
  }

  // Получение оборотов за период
  Future<List<Turnover>> getTurnovers(
    String tableName, {
    Map<String, String>? filters,
    String? period,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
  }) async {
    // Тут будет логика получения оборотов
    print('Получение оборотов для таблицы $tableName');
    
    // Для демонстрации возвращаем пустой список
    return [];
  }
}