library;

import '../imports.dart';

class TableManagerService {
  // Обязательные свойства базы данных
  final String directoryPath;
  final String databaseName;
  final TableType tableType;
  final List<String> measurements;
  final List<String> resources;
  final String databasePath;
  
  // Логгер
  static final Logger _logger = Logger('TableManagerService');

  // Конструктор для создания сервиса управления таблицами
  TableManagerService({
    required this.directoryPath,
    required this.databaseName,
    required this.tableType,
    required this.measurements,
    required this.resources,
  }) : databasePath = '$directoryPath/$databaseName';

  // Создает таблицы базы данных
  Future<void> createTables() async {
    _logger.fine('Создание таблиц для типа: $tableType');
    // Создаем файлы таблиц в зависимости от типа таблицы
    switch (tableType) {
      case TableType.balance:
        _logger.fine('Создание таблиц баланса: movements и aggregations');
        // Для балансовой таблицы создаем файлы движений и агрегаций
        await _createTableFile('movements');
        await _createTableFile('aggregations');
        break;
      case TableType.turnover:
        _logger.fine('Создание таблиц оборотов: movements и turnovers');
        // Для таблицы оборотов создаем файлы движений и оборотов
        await _createTableFile('movements');
        await _createTableFile('turnovers');
        break;
      case TableType.universal:
        _logger.fine('Создание универсальных таблиц: movements, aggregations и turnovers');
        // Для универсальной таблицы создаем все файлы
        await _createTableFile('movements');
        await _createTableFile('aggregations');
        await _createTableFile('turnovers');
        break;
    }
  }

  // Создает файл таблицы
  Future<void> _createTableFile(String tableName) async {
    final tablePath = '$databasePath/$databaseName.$tableName';
    final tableFile = File(tablePath);
    _logger.fine('Создаем файл таблицы: $tablePath');
    await tableFile.create();
    _logger.fine('Файл таблицы создан: $tablePath');
  }
}