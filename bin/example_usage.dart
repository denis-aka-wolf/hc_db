// Пример использования библиотеки hc_db
//
// Этот файл демонстрирует основные возможности базы данных hc_db,
// включая создание таблиц, добавление данных, выполнение запросов
// и использование движков агрегации и индексации.

import 'package:hc_db/hc_db.dart';
import 'dart:io';

void main() async {
  // Создаем директорию для баз данных
  final dbDir = 'db';
  Directory(dbDir).createSync(recursive: true);
  
  try {
    print('Создание базы данных в директории: $dbDir');
    
    // Создаем базу данных с примером параметров
    // Используем именованный конструктор для создания базы данных с путем и именем
    final db = await Database.createDatabase(
      directoryPath: dbDir,
      databaseName: 'example_database',
      tableType: TableType.balance,
      measurements: ['wallet_address', 'currency'],
      resources: ['amount', 'timestamp'],
    );
    
    // Инициализируем базу данных
    await db.init();
    
    print('База данных "example_database" успешно создана!');
    print('Структура базы данных:');
    print('- Директория: $dbDir/example_database');
    print('- Конфигурационный файл: $dbDir/example_database/example_database.config');
    print('- Файл таблицы движений: $dbDir/example_database/example_database.movements');
    print('- Файл таблицы итогов: $dbDir/example_database/example_database.aggregations');
    print('- Файл таблицы оборотов: $dbDir/example_database/example_database.turnovers');
    
    // Проверим, что файлы были созданы
    final dbPath = '$dbDir/example_database';
    print('Проверка созданных файлов:');
    print('Директория существует: ${Directory(dbPath).existsSync()}');
    print('Конфигурационный файл существует: ${File('$dbPath/example_database.config').existsSync()}');
    print('Файл движений существует: ${File('$dbPath/example_database.movements').existsSync()}');
    print('Файл агрегаций существует: ${File('$dbPath/example_database.aggregations').existsSync()}');
    print('Файл оборотов существует: ${File('$dbPath/example_database.turnovers').existsSync()}');
    
  } catch (e) {
    print('Ошибка при создании базы данных: $e');
  }
}