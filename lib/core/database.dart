library;

import 'dart:async';
import 'transaction.dart';
import 'cache.dart';

class Database {
  // Синглтон экземпляр базы данных
  static final Database _instance = Database._internal();
  factory Database() => _instance;
  Database._internal();

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
    print('База данных инициализирована');
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