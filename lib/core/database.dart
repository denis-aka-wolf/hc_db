library;

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'transaction.dart';
import 'cache.dart';
import '../tables/table_manager.dart';
import 'package:logging/logging.dart';

class Database {
  static final Database _instance = Database._internal();
  factory Database() => _instance;
  Database._internal();

  // Логгер
  static final Logger _logger = Logger('Database');

  // Управление соединениями
  final Map<String, DatabaseConnection> _connections = {};

  // Менеджер транзакций
  final TransactionManager _transactionManager = TransactionManager();

  // Кэш данных
  final Cache _cache = Cache();

  // Инициализация базы данных
  Future<void> init() async {
    // Инициализация компонентов
    await _cache.init();
    _logger.info('База данных инициализирована');
  }
  
  // Проверяет, существует ли база данных по указанному пути
  Future<bool> _databaseExists(String databasePath) async {
    final directory = Directory(databasePath);
    return await directory.exists();
  }
  
  // Создает директорию базы данных
  Future<void> _createDatabaseDirectory(String databasePath) async {
    final directory = Directory(databasePath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }
  
  // Создает файл конфигурации базы данных
  Future<void> _createConfigFile(
    String databasePath,
    String databaseName,
    TableType tableType,
    List<String> measurements,
    List<String> resources,
  ) async {
    final configPath = '$databasePath/$databaseName.config';
    final configFile = File(configPath);
    
    final configData = {
      'databaseName': databaseName,
      'tableType': tableType.toString(),
      'measurements': measurements,
      'resources': resources,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    final jsonString = JsonEncoder.withIndent('  ').convert(configData);
    await configFile.writeAsString(jsonString);
  }
  
  // Создает таблицы базы данных
  Future<void> _createTables(
    String databasePath,
    String databaseName,
    TableType tableType,
  ) async {
    // Создаем файлы таблиц
    await _createTableFile(databasePath, databaseName, 'movements');
    await _createTableFile(databasePath, databaseName, 'aggregations');
    await _createTableFile(databasePath, databaseName, 'turnovers');
  }
  
  // Создает файл таблицы
  Future<void> _createTableFile(
    String databasePath,
    String databaseName,
    String tableName,
  ) async {
    final tablePath = '$databasePath/${databaseName}.$tableName';
    final tableFile = File(tablePath);
    await tableFile.create();
  }
  
  // Создание базы данных
  /// Создает физическую структуру базы данных на диске
  ///
  /// @param directoryPath - путь к каталогу для создания базы данных
  /// @param databaseName - название базы данных
  /// @param tableType - тип таблицы
  /// @param measurements - список измерений
  /// @param resources - список ресурсов
  /// @return Future<void> - асинхронная операция создания базы данных
  Future<void> createDatabase(
    String directoryPath,
    String databaseName,
    TableType tableType,
    List<String> measurements,
    List<String> resources,
  ) async {
    // Проверка входных параметров
    if (directoryPath.isEmpty) {
      throw ArgumentError('Путь к каталогу не может быть пустым или null');
    }
    if (databaseName.isEmpty) {
      throw ArgumentError('Название базы данных не может быть пустым или null');
    }
    if (measurements.isEmpty) {
      throw ArgumentError('Список измерений не может быть пустым или null');
    }
    if (resources.isEmpty) {
      throw ArgumentError('Список ресурсов не может быть пустым или null');
    }
    
    // Создание пути к новой базе данных
    final databasePath = '$directoryPath/$databaseName';
    
    try {
      // Проверяем, существует ли уже такая база данных
      if (await _databaseExists(databasePath)) {
        throw StateError('База данных "$databaseName" уже существует');
      }
      
      // Создаем директорию базы данных
      await _createDatabaseDirectory(databasePath);
      
      // Создаем файл конфигурации
      await _createConfigFile(databasePath, databaseName, tableType, measurements, resources);
      
      // Создаем таблицы
      await _createTables(databasePath, databaseName, tableType);
      
      _logger.info('Создана база данных "$databaseName" в каталоге "$directoryPath"');
      _logger.info('Тип таблицы: $tableType');
      _logger.info('Измерения: $measurements');
      _logger.info('Ресурсы: $resources');
      
    } catch (error, stackTrace) {
      _logger.severe('Ошибка при создании базы данных "$databaseName": $error', error, stackTrace);
      rethrow;
    }
    
    // Инициализация базы данных
    await init();
  }

  // Создание соединения с базой данных
  DatabaseConnection connect(String id) {
    if (_connections.containsKey(id)) {
      return _connections[id]!;
    }
    
    final connection = DatabaseConnection(id);
    _connections[id] = connection;
    return connection;
  }

  // Закрытие соединения
  void disconnect(String id) {
    _connections.remove(id);
  }

  // Получение менеджера транзакций
  TransactionManager get transactionManager => _transactionManager;

  // Получение кэша
  Cache get cache => _cache;

  // Выполнение транзакции
  Future<T> executeTransaction<T>(
    Future<T> Function(Transaction) transactionFunction,
  ) async {
    final transaction = _transactionManager.beginTransaction();
    try {
      final result = await transactionFunction(transaction);
      await transaction.commit();
      return result;
    } catch (e) {
      await transaction.rollback();
      rethrow;
    }
  }
}

// Соединение с базой данных
class DatabaseConnection {
  final String id;
  bool _isOpen = false;

  DatabaseConnection(this.id);

  bool get isOpen => _isOpen;

  // Открытие соединения
  void open() {
    _isOpen = true;
    print('Соединение $id открыто');
  }

  // Закрытие соединения
  void close() {
    _isOpen = false;
    print('Соединение $id закрыто');
  }
}