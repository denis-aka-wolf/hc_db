library;

import 'dart:async';
import '../core/database.dart';

// Тип таблицы
enum TableType {
  balance,    // Остатки
  turnover,   // Обороты
  universal,  // Универсальная
}

// Структура таблицы
class Table {
  final String name;
  final TableType type;
  final List<String> measurements;
  final List<String> resources;
  final bool useAggregations;
  final bool useTurnovers;
  
  Table({
    required this.name,
    required this.type,
    required this.measurements,
    required this.resources,
    this.useAggregations = true,
    this.useTurnovers = true,
  });

  // Преобразование в мапу для хранения
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'measurements': measurements,
      'resources': resources,
      'useAggregations': useAggregations,
      'useTurnovers': useTurnovers,
    };
  }

  // Создание из мапы
  factory Table.fromMap(Map<String, dynamic> map) {
    return Table(
      name: map['name'],
      type: TableType.values.firstWhere(
        (t) => t.toString().split('.').last == map['type'],
        orElse: () => TableType.balance,
      ),
      measurements: List<String>.from(map['measurements']),
      resources: List<String>.from(map['resources']),
      useAggregations: map['useAggregations'] ?? true,
      useTurnovers: map['useTurnovers'] ?? true,
    );
  }
}

// Менеджер таблиц - управляет созданием, модификацией и удалением таблиц
class TableManager {
  final Database database;
  final Map<String, Table> _tables = {};
  final Map<String, String> _tableMetadata = {};

  TableManager(this.database);

  // Создание таблицы
  Future<void> createTable(Table table) async {
    // Проверка наличия таблицы
    if (_tables.containsKey(table.name)) {
      throw StateError('Таблица ${table.name} уже существует');
    }

    // Сохранение метаданных таблицы
    _tableMetadata[table.name] = table.toMap().toString();
    
    // Добавление таблицы в список
    _tables[table.name] = table;
    
    print('Создана таблица: ${table.name}');
  }

  // Получение таблицы
  Table? getTable(String name) {
    return _tables[name];
  }

  // Получение всех таблиц
  Iterable<Table> get tables => _tables.values;

  // Удаление таблицы
  Future<void> dropTable(String name) async {
    if (!_tables.containsKey(name)) {
      throw StateError('Таблица $name не существует');
    }
    
    // Удаление метаданных
    _tableMetadata.remove(name);
    
    // Удаление таблицы
    _tables.remove(name);
    
    print('Удалена таблица: $name');
  }

  // Проверка существования таблицы
  bool tableExists(String name) {
    return _tables.containsKey(name);
  }

  // Получение метаданных таблицы
  String? getTableMetadata(String name) {
    return _tableMetadata[name];
  }
}