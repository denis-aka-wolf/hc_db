import 'dart:io';
import 'package:hc_db/hc_db.dart';

void main() async {
 // Создаем базу данных и проверяем, что происходит с файлами
  final db = await Database.createDatabase(
    directoryPath: './db',
    databaseName: 'debug_header',
    tableType: TableType.universal,
    measurements: ['measurement1'],
    resources: ['resource1'],
  );
  
  // Проверяем содержимое файла
 final movementsFile = File('./db/debug_header/debug_header.movements');
  final content = await movementsFile.readAsString();
  print('Содержимое файла после createDatabase: ${content.substring(0, content.length < 100 ? content.length : 100)}...');
  
  // Повторно инициализируем
  await db.init();
  
  final contentAfterInit = await movementsFile.readAsString();
  print('Содержимое файла после init: ${contentAfterInit.substring(0, contentAfterInit.length < 100 ? contentAfterInit.length : 100)}...');
  
  // Еще раз
  await db.init();
  
  final contentAfterSecondInit = await movementsFile.readAsString();
  print('Содержимое файла после второго init: ${contentAfterSecondInit.substring(0, contentAfterSecondInit.length < 150 ? contentAfterSecondInit.length : 150)}...');
  
  print('Количество маркеров заголовка: ${contentAfterSecondInit.split('// DATABASE HEADER').length}');
  
  // Удалим тестовую базу данных
  final dbDir = Directory('./db/debug_header');
  if (await dbDir.exists()) {
    await dbDir.delete(recursive: true);
  }
}