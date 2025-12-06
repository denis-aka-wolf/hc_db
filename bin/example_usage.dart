// Пример использования библиотеки hc_db
//
// Этот файл демонстрирует основные возможности базы данных hc_db,
// включая создание таблиц, добавление данных, выполнение запросов
// и использование движков агрегации и индексации.

import 'package:hc_db/hc_db.dart';
import 'dart:io';

void main() async {
  // Создаем экземпляр базы данных
  final db = Database();
  
  // Инициализируем базу данных
  await db.init();
  
  // Создаем директорию для баз данных
  final dbDir = 'db';
  Directory(dbDir).createSync(recursive: true);
  
  try {
    print('Создание базы данных в директории: $dbDir');
    
    // Создаем базу данных с примером параметров
    await db.createDatabase(
      dbDir,
      'example_database',
      TableType.balance,
      ['wallet_address', 'currency'],
      ['amount', 'timestamp'],
    );
    
    print('База данных "example_database" успешно создана!');
    print('Структура базы данных:');
    print('- Директория: $dbDir/example_database');
    print('- Конфигурационный файл: $dbDir/example_database/example_database.config');
    print('- Файл таблицы движений: $dbDir/example_database/example_database.movements');
    print('- Файл таблицы итогов: $dbDir/example_database/example_database.aggregations');
    print('- Файл таблицы оборотов: $dbDir/example_database/example_database.turnovers');
    
  } catch (e) {
    print('Ошибка при создании базы данных: $e');
  }
}