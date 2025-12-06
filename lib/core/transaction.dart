library;

import 'dart:async';

// Транзакция базы данных
class Transaction {
  final String id;
  final DateTime startTime;
  bool _committed = false;
  bool _rolledBack = false;

  Transaction(this.id, this.startTime);

  // Подтверждение транзакции
  Future<void> commit() async {
    if (_committed || _rolledBack) {
      throw StateError('Транзакция уже завершена');
    }
    _committed = true;
    print('Транзакция $id подтверждена');
  }

  // Откат транзакции
  Future<void> rollback() async {
    if (_committed || _rolledBack) {
      throw StateError('Транзакция уже завершена');
    }
    _rolledBack = true;
    print('Транзакция $id отменена');
  }

  bool get isCommitted => _committed;
  bool get isRolledBack => _rolledBack;
}

// Менеджер транзакций
class TransactionManager {
  final Map<String, Transaction> _activeTransactions = {};
  int _transactionCounter = 0;

  // Создание новой транзакции
  Transaction beginTransaction() {
    final transactionId = 'txn_${++_transactionCounter}';
    final transaction = Transaction(transactionId, DateTime.now());
    _activeTransactions[transactionId] = transaction;
    print('Начата транзакция $transactionId');
    return transaction;
  }

  // Получение активной транзакции
  Transaction? getTransaction(String id) {
    return _activeTransactions[id];
  }

  // Завершение транзакции
  void endTransaction(String id) {
    _activeTransactions.remove(id);
    print('Транзакция $id завершена');
  }
}