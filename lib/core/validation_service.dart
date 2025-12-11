library;

import '../imports.dart';

class ValidationService {
  /// Проверяет корректность пути к каталогу
  /// 
  /// Выполняет проверки:
  /// - Путь не пустой
  /// - Каталог существует
  /// - Указанный путь является каталогом, а не файлом
  /// 
  /// @param directoryPath путь к каталогу для проверки
  /// @throws ArgumentError если путь некорректный
  static Future<void> validateDirectoryPath(String directoryPath) async {
    // Проверка на пустоту
    if (directoryPath.isEmpty) {
      throw ArgumentError('Путь к каталогу не может быть пустым');
    }
    
    // Проверка корректности пути и типа
    try {
      final directory = Directory(directoryPath);
      
      // Используем '!' для уверенности, что directory.exists() не вернет null,
      // хотя в данном случае он возвращает Future<bool>.
      if (!await directory.exists()) {
        throw ArgumentError('Каталог не существует: $directoryPath');
      }
        
      final stat = await directory.stat();
      if (stat.type != FileSystemEntityType.directory) {
        throw ArgumentError('Указанный путь не является каталогом: $directoryPath');
      }
    } catch (e) {
      // Используем короткий оператор '??' для обработки типа исключения.
      // Если 'e' является ArgumentError, перебрасываем 'e', иначе создаем новое.
      throw (e is ArgumentError) 
        ? e 
        : ArgumentError('Некорректный путь каталогу: $directoryPath (${e.toString()})');
    }
  }

  /// Проверяет корректность названия базы данных
  ///
  /// Название базы данных должно:
  /// - Не быть пустым
  /// - Начинаться с буквы
  /// - Содержать только латинские буквы, цифры, символы '-' и '_'
  ///
  /// @param databaseName название базы данных для проверки
  /// @throws ArgumentError если название некорректно
  static Future<void> validateDatabaseName(String databaseName) async {
    // Проверка на пустоту
    if (databaseName.isEmpty) {
      throw ArgumentError('Название базы данных не может быть пустым');
    }
    
    // Проверка, что первым символом является буква
    if (!RegExp(r'^[a-zA-Z]').hasMatch(databaseName)) {
      throw ArgumentError('Название базы данных должно начинаться с буквы');
    }
    
    // Проверка, что все символы соответствуют допустимым
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(databaseName)) {
      throw ArgumentError('Название базы данных может содержать только латинские буквы, цифры, символы "-" и "_"');
    }
  }

  /// Проверяет корректность названия измерения или ресурса
  ///
  /// Название измерения или ресурса должно:
  /// - Не быть пустым
  /// - Начинаться с буквы
  /// - Содержать только латинские буквы, цифры, символы '-' и '_'
  ///
  /// @param name название измерения или ресурса для проверки
  /// @throws ArgumentError если название некорректно
  static bool isValidMeasurementOrResourceName(String name) {
    // Проверка на пустоту
    if (name.isEmpty) {
      return false;
    }
    
    // Проверка, что первым символом является буква
    if (!RegExp(r'^[a-zA-Z]').hasMatch(name)) {
      return false;
    }
    
    // Проверка, что все символы соответствуют допустимым
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name)) {
      return false;
    }
    
    return true;
  }

  /// Валидирует список названий измерений или ресурсов
  ///
  /// @param names список названий для валидации
  /// @param type тип названий ('измерения' или 'ресурсы') для сообщений об ошибках
  /// @throws ArgumentError если какие-либо названия некорректны
  static void validateMeasurementOrResourceNames(List<String> names, String type) {
    for (final name in names) {
      if (!isValidMeasurementOrResourceName(name)) {
        throw ArgumentError('Некорректное название $type: "$name". Название должно начинаться с буквы и содержать только латинские буквы, цифры, символы "-" и "_"');
      }
    }
  }
}