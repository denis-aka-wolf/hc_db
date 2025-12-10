import 'dart:io';
import 'package:hc_db/hc_db.dart';

void main() async {
 // Создаем базу данных и проверяем, что происходит с файлами
  final db = await Database.createDatabase(
    directoryPath: './db',
    databaseName: 'debug_header_detailed',
    tableType: TableType.universal,
    measurements: ['measurement1'],
    resources: ['resource1'],
  );
  
  // Проверяем содержимое файла сразу после создания
  final movementsFile = File('./db/debug_header_detailed/debug_header_detailed.movements');
  final contentAfterCreate = await movementsFile.readAsString();
  print('Содержимое файла после createDatabase (длина: ${contentAfterCreate.length}):');
  print(contentAfterCreate);
  print('startsWith("// DATABASE HEADER"): ${contentAfterCreate.startsWith('// DATABASE HEADER')}');
  print('trimLeft().startsWith("// DATABASE HEADER"): ${contentAfterCreate.trimLeft().startsWith('// DATABASE HEADER')}');
  print('---');
  
  // Повторно инициализируем
  await db.init();
  
  final contentAfterFirstInit = await movementsFile.readAsString();
  print('Содержимое файла после первого init (длина: ${contentAfterFirstInit.length}):');
  print(contentAfterFirstInit);
  print('startsWith("// DATABASE HEADER"): ${contentAfterFirstInit.startsWith('// DATABASE HEADER')}');
  print('trimLeft().startsWith("// DATABASE HEADER"): ${contentAfterFirstInit.trimLeft().startsWith('// DATABASE HEADER')}');
  print('---');
  
  // Еще раз
  await db.init();
  
  final contentAfterSecondInit = await movementsFile.readAsString();
  print('Содержимое файла после второго init (длина: ${contentAfterSecondInit.length}):');
  print(contentAfterSecondInit);
  print('startsWith("// DATABASE HEADER"): ${contentAfterSecondInit.startsWith('// DATABASE HEADER')}');
  print('trimLeft().startsWith("// DATABASE HEADER"): ${contentAfterSecondInit.trimLeft().startsWith('// DATABASE HEADER')}');
  print('Количество маркеров заголовка: ${contentAfterSecondInit.split('// DATABASE HEADER').length}');
  
  final contentAfterSecondSplit = contentAfterSecondInit.trimLeft().split('// DATABASE HEADER');
  print('Количество найденных элементов: ${contentAfterSecondSplit.length == 0 ? 0 : contentAfterSecondSplit.length-1} элементов в файле');
      
  // Удалим тестовую базу данных
  final dbDir = Directory('./db/debug_header_detailed');
  if (await dbDir.exists()) {
    await dbDir.delete(recursive: true);
  }
}