library;

import 'package:logging/logging.dart';

/// Соединение с базой данных
class DatabaseConnection {
  final String id;
  bool _isOpen = false;

  DatabaseConnection(this.id);

  bool get isOpen => _isOpen;

  // Открытие соединения
  void open() {
    _isOpen = true;
    _logger.fine('Соединение $id открыто');
  }

  // Закрытие соединения
  void close() {
    _isOpen = false;
    _logger.fine('Соединение $id закрыто');
  }
  
  static final Logger _logger = Logger('DatabaseConnection');
}