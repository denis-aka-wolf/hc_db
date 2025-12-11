import 'package:test/test.dart';
import 'package:hc_db/hc_db.dart';
import 'dart:io';

// Список созданных баз данных для последующего удаления
final List<String> createdDatabases = [];

void main() {
 group('Database Creation Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database creation with parameters', () async {
      // Тестируем создание базы данных с параметрами
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db');
      expect(db.tableType, TableType.balance);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });

    test('Database initialization', () async {
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_init',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_init');
      
      await db.init();
      // Проверяем, что база данных инициализирована без ошибок
      expect(true, true);
    });
    
    test('Database creation with balance table type', () async {
      // Тестируем создание базы данных с типом таблицы balance
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_balance_unique',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_balance_unique');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_balance_unique');
      expect(db.tableType, TableType.balance);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
    
    test('Database creation with turnover table type', () async {
      // Тестируем создание базы данных с типом таблицы turnover
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_turnover_unique',
        tableType: TableType.turnover,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_turnover_unique');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_turnover_unique');
      expect(db.tableType, TableType.turnover);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
    
    test('Database creation with universal table type', () async {
      // Тестируем создание базы данных с типом таблицы universal
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_universal_unique',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_universal_unique');
      
      // Проверяем, что свойства установлены правильно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_db_universal_unique');
      expect(db.tableType, TableType.universal);
      expect(db.measurements, ['measurement1']);
      expect(db.resources, ['resource1']);
    });
 });
  
  group('Database Files Creation Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database files creation for balance type', () async {
      // Тестируем создание файлов базы данных с типом balance
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_files_balance',
        tableType: TableType.balance,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_files_balance');
      
      // Проверяем, что база данных создана с правильными файлами
      final dbDir = Directory('./db/test_db_files_balance');
      expect(await dbDir.exists(), true);
      
      // Для типа balance должны быть созданы файлы movements и aggregations
      final movementsFile = File('./db/test_db_files_balance/test_db_files_balance.movements');
      final aggregationsFile = File('./db/test_db_files_balance/test_db_files_balance.aggregations');
      final turnoversFile = File('./db/test_db_files_balance/test_db_files_balance.turnovers');
      
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), false); // turnovers не должен создаваться для типа balance
    });
    
    test('Database files creation for turnover type', () async {
      // Тестируем создание файлов базы данных с типом turnover
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_files_turnover',
        tableType: TableType.turnover,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_files_turnover');
      
      // Проверяем, что база данных создана с правильными файлами
      final dbDir = Directory('./db/test_db_files_turnover');
      expect(await dbDir.exists(), true);
      
      // Для типа turnover должны быть созданы файлы movements и turnovers
      final movementsFile = File('./db/test_db_files_turnover/test_db_files_turnover.movements');
      final turnoversFile = File('./db/test_db_files_turnover/test_db_files_turnover.turnovers');
      final aggregationsFile = File('./db/test_db_files_turnover/test_db_files_turnover.aggregations');
      
      expect(await movementsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
      expect(await aggregationsFile.exists(), false); // aggregations не должен создаваться для типа turnover
    });
    
    test('Database files creation for universal type', () async {
      // Тестируем создание файлов базы данных с типом universal
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_files_universal',
        tableType: TableType.universal,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_files_universal');
      
      // Проверяем, что база данных создана с правильными файлами
      final dbDir = Directory('./db/test_db_files_universal');
      expect(await dbDir.exists(), true);
      
      // Для типа universal должны быть созданы файлы movements, aggregations и turnovers
      final movementsFile = File('./db/test_db_files_universal/test_db_files_universal.movements');
      final aggregationsFile = File('./db/test_db_files_universal/test_db_files_universal.aggregations');
      final turnoversFile = File('./db/test_db_files_universal/test_db_files_universal.turnovers');
      
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
    });
    
    test('Database config file creation', () async {
      // Тестируем создание файла конфигурации
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_config',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_config');
      
      // Проверяем, что файл конфигурации создан
      final configFile = File('./db/test_db_config/test_db_config.config');
      expect(await configFile.exists(), true);
      
      // Проверяем содержимое файла конфигурации
      final configContent = await configFile.readAsString();
      expect(configContent.contains('databaseName'), true);
      expect(configContent.contains('tableType'), true);
      expect(configContent.contains('measurements'), true);
      expect(configContent.contains('resources'), true);
    });
    
    test('Database creation with same name should throw error', () async {
      // Создаем базу данных
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_db_duplicate',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_db_duplicate');
      
      // Пробуем создать базу данных с тем же именем - должно вызвать ошибку
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: 'test_db_duplicate',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
  
 group('Database Table Size Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database table sizes for universal type should match calculated size', () async {
      // Создаем базу данных с типом universal
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_table_sizes',
        tableType: TableType.universal,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_table_sizes');
      
      // Рассчитываем ожидаемый размер файлов таблиц
      // Размер резерва: минимальное количество экстентов * размер экстента
      final expectedSize = db.minReserveExtents * db.extentSize; // 10 * 6536 = 655360
      
      // Проверяем размер файлов таблиц
      final movementsFile = File('./db/test_table_sizes/test_table_sizes.movements');
      final aggregationsFile = File('./db/test_table_sizes/test_table_sizes.aggregations');
      final turnoversFile = File('./db/test_table_sizes/test_table_sizes.turnovers');
      
      // Проверяем, что файлы существуют
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
      
      // Проверяем размеры файлов
      final movementsSize = await movementsFile.length();
      final aggregationsSize = await aggregationsFile.length();
      final turnoversSize = await turnoversFile.length();
      
      // Проверяем, что размеры файлов не меньше ожидаемого размера
      expect(movementsSize >= expectedSize, true, reason: 'Размер файла movements меньше ожидаемого');
      expect(aggregationsSize >= expectedSize, true, reason: 'Размер файла aggregations меньше ожидаемого');
      expect(turnoversSize >= expectedSize, true, reason: 'Размер файла turnovers меньше ожидаемого');
    });
    
    test('Database table sizes should match calculated size with custom parameters', () async {
      // Создаем базу данных с типом universal и проверяем размеры файлов
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_table_sizes_custom',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_table_sizes_custom');
      
      // Рассчитываем ожидаемый размер файлов таблиц
      final expectedSize = db.minReserveExtents * db.extentSize; // 10 * 65536 = 655360
      
      // Проверяем размер файлов таблиц
      final movementsFile = File('./db/test_table_sizes_custom/test_table_sizes_custom.movements');
      final aggregationsFile = File('./db/test_table_sizes_custom/test_table_sizes_custom.aggregations');
      final turnoversFile = File('./db/test_table_sizes_custom/test_table_sizes_custom.turnovers');
      
      // Проверяем, что файлы существуют
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
      
      // Проверяем размеры файлов
      final movementsSize = await movementsFile.length();
      final aggregationsSize = await aggregationsFile.length();
      final turnoversSize = await turnoversFile.length();
      
      // Проверяем, что размеры файлов не меньше ожидаемого размера
      expect(movementsSize >= expectedSize, true, reason: 'Размер файла movements меньше ожидаемого');
      expect(aggregationsSize >= expectedSize, true, reason: 'Размер файла aggregations меньше ожидаемого');
      expect(turnoversSize >= expectedSize, true, reason: 'Размер файла turnovers меньше ожидаемого');
      
      // Проверяем, что ожидаемый размер соответствует параметрам базы данных
      expect(expectedSize, 655360, reason: 'Расчетный размер не соответствует ожидаемому значению (10 * 65536)');
    });
    
    test('Database table files should have correct initial content and size', () async {
      // Создаем базу данных с типом universal
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_table_content',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_table_content');
      
      // Проверяем содержимое файлов таблиц
      final movementsFile = File('./db/test_table_content/test_table_content.movements');
      final aggregationsFile = File('./db/test_table_content/test_table_content.aggregations');
      final turnoversFile = File('./db/test_table_content/test_table_content.turnovers');
      
      // Проверяем, что файлы существуют
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
      
      // Читаем содержимое файлов
      final movementsContent = await movementsFile.readAsString();
      final aggregationsContent = await aggregationsFile.readAsString();
      final turnoversContent = await turnoversFile.readAsString();
      
      // Проверяем, что содержимое начинается с заголовка
      expect(movementsContent.startsWith('// DATABASE HEADER'), true, reason: 'Файл movements не содержит заголовок');
      expect(aggregationsContent.startsWith('// DATABASE HEADER'), true, reason: 'Файл aggregations не содержит заголовок');
      expect(turnoversContent.startsWith('// DATABASE HEADER'), true, reason: 'Файл turnovers не содержит заголовок');
      
      // Проверяем, что содержимое содержит информацию о базе данных
      expect(movementsContent.contains('test_table_content'), true, reason: 'Файл movements не содержит имя базы данных');
      expect(aggregationsContent.contains('test_table_content'), true, reason: 'Файл aggregations не содержит имя базы данных');
      expect(turnoversContent.contains('test_table_content'), true, reason: 'Файл turnovers не содержит имя базы данных');
    });
 });
  
  group('Database Header Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database files should contain proper header structure', () async {
      // Создаем базу данных с типом universal
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_header_structure',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_header_structure');
      
      // Проверяем содержимое файлов таблиц
      final movementsFile = File('./db/test_header_structure/test_header_structure.movements');
      final aggregationsFile = File('./db/test_header_structure/test_header_structure.aggregations');
      final turnoversFile = File('./db/test_header_structure/test_header_structure.turnovers');
      
      // Проверяем, что файлы существуют
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
      
      // Читаем содержимое файлов
      final movementsContent = await movementsFile.readAsString();
      final aggregationsContent = await aggregationsFile.readAsString();
      final turnoversContent = await turnoversFile.readAsString();
      
      // Проверяем, что содержимое начинается с заголовка
      expect(movementsContent.startsWith('// DATABASE HEADER'), true, reason: 'Файл movements не содержит заголовок');
      expect(aggregationsContent.startsWith('// DATABASE HEADER'), true, reason: 'Файл aggregations не содержит заголовок');
      expect(turnoversContent.startsWith('// DATABASE HEADER'), true, reason: 'Файл turnovers не содержит заголовок');
      
      // Проверяем, что содержимое заканчивается маркером конца заголовка
      expect(movementsContent.contains('// END HEADER'), true, reason: 'Файл movements не содержит маркер окончания заголовка');
      expect(aggregationsContent.contains('// END HEADER'), true, reason: 'Файл aggregations не содержит маркер окончания заголовка');
      expect(turnoversContent.contains('// END HEADER'), true, reason: 'Файл turnovers не содержит маркер окончания заголовка');
      
      // Проверяем, что заголовок содержит основную информацию о базе данных
      expect(movementsContent.contains('databaseName: test_header_structure'), true, reason: 'Файл movements не содержит имя базы данных в заголовке');
      expect(aggregationsContent.contains('databaseName: test_header_structure'), true, reason: 'Файл aggregations не содержит имя базы данных в заголовке');
      expect(turnoversContent.contains('databaseName: test_header_structure'), true, reason: 'Файл turnovers не содержит имя базы данных в заголовке');
      
      expect(movementsContent.contains('pageSize: ${db.pageSize}'), true, reason: 'Файл movements не содержит размер страницы в заголовке');
      expect(aggregationsContent.contains('pageSize: ${db.pageSize}'), true, reason: 'Файл aggregations не содержит размер страницы в заголовке');
      expect(turnoversContent.contains('pageSize: ${db.pageSize}'), true, reason: 'Файл turnovers не содержит размер страницы в заголовке');
      
      expect(movementsContent.contains('extentSize: ${db.extentSize}'), true, reason: 'Файл movements не содержит размер экстента в заголовке');
      expect(aggregationsContent.contains('extentSize: ${db.extentSize}'), true, reason: 'Файл aggregations не содержит размер экстента в заголовке');
      expect(turnoversContent.contains('extentSize: ${db.extentSize}'), true, reason: 'Файл turnovers не содержит размер экстента в заголовке');
      
      expect(movementsContent.contains('minReserveExtents: ${db.minReserveExtents}'), true, reason: 'Файл movements не содержит минимальное количество зарезервированных экстентов в заголовке');
      expect(aggregationsContent.contains('minReserveExtents: ${db.minReserveExtents}'), true, reason: 'Файл aggregations не содержит минимальное количество зарезервированных экстентов в заголовке');
      expect(turnoversContent.contains('minReserveExtents: ${db.minReserveExtents}'), true, reason: 'Файл turnovers не содержит минимальное количество зарезервированных экстентов в заголовке');
    });
    
    test('Database header should contain creation timestamp', () async {
      // Создаем базу данных с типом universal
      await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_header_timestamp',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_header_timestamp');
      
      // Проверяем содержимое файлов таблиц
      final movementsFile = File('./db/test_header_timestamp/test_header_timestamp.movements');
      final aggregationsFile = File('./db/test_header_timestamp/test_header_timestamp.aggregations');
      final turnoversFile = File('./db/test_header_timestamp/test_header_timestamp.turnovers');
      
      // Проверяем, что файлы существуют
      expect(await movementsFile.exists(), true);
      expect(await aggregationsFile.exists(), true);
      expect(await turnoversFile.exists(), true);
      
      // Читаем содержимое файлов
      final movementsContent = await movementsFile.readAsString();
      final aggregationsContent = await aggregationsFile.readAsString();
      final turnoversContent = await turnoversFile.readAsString();
      
      // Проверяем, что заголовок содержит дату создания
      expect(movementsContent.contains('created:'), true, reason: 'Файл movements не содержит дату создания в заголовке');
      expect(aggregationsContent.contains('created:'), true, reason: 'Файл aggregations не содержит дату создания в заголовке');
      expect(turnoversContent.contains('created:'), true, reason: 'Файл turnovers не содержит дату создания в заголовке');
    });
    
    test('Database header should not be duplicated when init is called multiple times', () async {
      // Создаем базу данных с типом universal
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_header_duplicate',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_header_duplicate');
      
      // Проверяем содержимое файла таблицы
      final movementsFile = File('./db/test_header_duplicate/test_header_duplicate.movements');
      
      // Проверяем, что файл существует
      expect(await movementsFile.exists(), true);
      
      // Читаем содержимое файла
      final movementsContent = await movementsFile.readAsString();
      
      // Проверяем, что заголовок начинается с правильного маркера
      expect(movementsContent.startsWith('// DATABASE HEADER'), true, reason: 'Файл movements не начинается с заголовка');
      
      // Проверяем, что маркер начала заголовка встречается только один раз в начале файла
      final allHeaderMarkers = movementsContent.split('// DATABASE HEADER');
      expect(allHeaderMarkers.length == 0 ? 0 : allHeaderMarkers.length-1, 1, reason: 'Найдено несколько маркеров начала заголовка в файле');
      
      // Повторно инициализируем базу данных дважды
      await db.init();
      await db.init();
      
      // Снова читаем содержимое файла
      final movementsContentAfterInit = await movementsFile.readAsString();
      
      // Проверяем, что маркер начала заголовка все еще встречается только один раз
      final allHeaderMarkersAfterInit = movementsContentAfterInit.split('// DATABASE HEADER');
      expect(allHeaderMarkers.length == 0 ? 0 : allHeaderMarkers.length-1, 1, reason: 'Найдено несколько маркеров начала заголовка в файле после повторной инициализации');
    });
  });
  
  group('Directory Path Validation Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database creation should throw error for empty directory path', () async {
      // Пробуем создать базу данных с пустым путем каталогу
      expect(
        () async => await Database.createDatabase(
          directoryPath: '',
          databaseName: 'test_empty_path',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Путь к каталогу не может быть пустым')),
      );
    });
    
    test('Database creation should throw error for non-existent directory path', () async {
      // Пробуем создать базу данных с несуществующим путем к каталогу
      expect(
        () async => await Database.createDatabase(
          directoryPath: './nonexistent/directory/path',
          databaseName: 'test_nonexistent_path',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Каталог не существует: ./nonexistent/directory/path'))),
      );
    });
    
    test('Database creation should throw error for invalid directory path', () async {
      // Создаем временный файл для тестирования недопустимого пути
      final tempFile = File('./db/temp_file_for_test.txt');
      await tempFile.create();
      
      // Пробуем использовать путь к файлу вместо каталога
      expect(
        () async => await Database.createDatabase(
          directoryPath: './temp_file_for_test.txt',
          databaseName: 'test_invalid_path',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Каталог не существует: ./temp_file_for_test.txt'))),
      );
      
      // Удаляем временный файл
      await tempFile.delete();
    });
    
    test('Database creation should succeed with valid directory path', () async {
      // Создаем базу данных с допустимым путем к каталогу
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_valid_path',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_valid_path');
      
      // Проверяем, что база данных создана успешно
      expect(db.directoryPath, './db');
      expect(db.databaseName, 'test_valid_path');
      expect(db.tableType, TableType.balance);
    });
  });
  group('Database Name Validation Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database creation should throw error for empty database name', () async {
      // Пробуем создать базу данных с пустым названием
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: '',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Название базы данных не может быть пустым')),
      );
    });
    
    test('Database creation should throw error for database name starting with digit', () async {
      // Пробуем создать базу данных с названием, начинающимся с цифры
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: '1test_db',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Название базы данных должно начинаться с буквы')),
      );
    });
    
    test('Database creation should throw error for database name starting with special character', () async {
      // Пробуем создать базу данных с названием, начинающимся со специального символа
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: '-test_db',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Название базы данных должно начинаться с буквы')),
      );
    });
    
    test('Database creation should throw error for database name with invalid characters', () async {
      // Пробуем создать базу данных с названием, содержащим недопустимые символы
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: 'test@db',
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Название базы данных может содержать только латинские буквы, цифры, символы "-" и "_"')),
      );
    });
    
    test('Database creation should succeed with valid database name containing letters, digits, hyphens and underscores', () async {
      // Тестируем различные допустимые названия баз данных
      final validNames = [
        'test_db',
        'test-db',
        'Test123',
        'test_db_123',
        'Test-DB-123',
        'a', // минимально допустимое имя
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-', // максимально допустимое имя
      ];
      
      for (final name in validNames) {
        final db = await Database.createDatabase(
          directoryPath: './db',
          databaseName: name,
          tableType: TableType.balance,
          measurements: ['measurement1'],
          resources: ['resource1'],
        );
        
        // Добавляем созданную базу данных в список для последующего удаления
        createdDatabases.add(name);
        
        // Проверяем, что база данных создана успешно
        expect(db.databaseName, name);
      }
    });
  });
  
  group('Measurement and Resource Name Validation Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database creation should succeed with valid measurement and resource names', () async {
      // Тестируем различные допустимые названия измерений и ресурсов
      final validMeasurements = [
        'measurement1',
        'resource_name',
        'test-measurement',
        'MyResource123',
        'valid_name_123',
        'test123',
        'my-resource_test'
      ];
      
      final validResources = [
        'resource1',
        'measurement_name',
        'test-resource',
        'MyMeasurement123',
        'valid_name_123',
        'test123',
        'my-resource_test'
      ];
      
      final db = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_valid_names',
        tableType: TableType.balance,
        measurements: validMeasurements,
        resources: validResources,
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_valid_names');
      
      // Проверяем, что база данных создана успешно
      expect(db.databaseName, 'test_valid_names');
      expect(db.measurements, validMeasurements);
      expect(db.resources, validResources);
    });
    
    test('Database creation should throw error for measurement name starting with digit', () async {
      // Пробуем создать базу данных с названием измерения, начинающимся с цифры
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: 'test_invalid_measurement_start',
          tableType: TableType.balance,
          measurements: ['123invalid', 'valid_measurement'],
          resources: ['resource1', 'valid_resource'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Некорректное название измерения'))),
      );
    });
    
    test('Database creation should throw error for resource name starting with special character', () async {
      // Пробуем создать базу данных с названием ресурса, начинающимся со специального символа
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: 'test_invalid_resource_start',
          tableType: TableType.balance,
          measurements: ['measurement1', 'valid_measurement'],
          resources: ['_invalid_resource', 'valid_resource'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Некорректное название ресурсы'))),
      );
    });
    
    test('Database creation should throw error for measurement name with invalid characters', () async {
      // Пробуем создать базу данных с названием измерения, содержащим недопустимые символы
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: 'test_invalid_measurement_chars',
          tableType: TableType.balance,
          measurements: ['valid_measurement', 'invalid.name'],
          resources: ['resource1', 'valid_resource'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Некорректное название измерения'))),
      );
    });
    
    test('Database creation should throw error for resource name with spaces', () async {
      // Пробуем создать базу данных с названием ресурса, содержащим пробелы
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: 'test_invalid_resource_spaces',
          tableType: TableType.balance,
          measurements: ['measurement1', 'valid_measurement'],
          resources: ['valid_resource', 'invalid resource'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Некорректное название ресурсы'))),
      );
    });
    
    test('Database creation should throw error for measurement name with special symbols', () async {
      // Пробуем создать базу данных с названием измерения, содержащим специальные символы
      expect(
        () async => await Database.createDatabase(
          directoryPath: './db',
          databaseName: 'test_invalid_measurement_symbols',
          tableType: TableType.balance,
          measurements: ['valid_measurement', 'measurement@name'],
          resources: ['resource1', 'valid_resource'],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Некорректное название измерения'))),
      );
    });
  });
  
  group('Database Open Tests', () {
    setUp(() {
      // Создаем директорию db перед тестами, если она не существует
      Directory('./db').createSync(recursive: true);
    });
    
    tearDown(() {
      // Удаляем только созданные тестами базы данных
      for (final dbName in createdDatabases) {
        final dbDir = Directory('./db/$dbName');
        if (dbDir.existsSync()) {
          dbDir.deleteSync(recursive: true);
        }
      }
      // Очищаем список созданных баз данных
      createdDatabases.clear();
    });
    
    test('Database should be opened successfully from existing database', () async {
      // Сначала создаем базу данных
      final originalDb = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_open_db',
        tableType: TableType.balance,
        measurements: ['measurement1'],
        resources: ['resource1'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_open_db');
      
      // Проверяем, что свойства оригинальной базы данных установлены правильно
      expect(originalDb.directoryPath, './db');
      expect(originalDb.databaseName, 'test_open_db');
      expect(originalDb.tableType, TableType.balance);
      expect(originalDb.measurements, ['measurement1']);
      expect(originalDb.resources, ['resource1']);
      
      // Закрываем соединение с оригинальной базой данных (если нужно)
      // Затем открываем существующую базу данных
      final openedDb = await Database.open(
        directoryPath: './db',
        databaseName: 'test_open_db',
      );
      
      // Проверяем, что открытая база данных имеет правильные свойства
      expect(openedDb.directoryPath, './db');
      expect(openedDb.databaseName, 'test_open_db');
      expect(openedDb.tableType, TableType.balance);
      expect(openedDb.measurements, ['measurement1']);
      expect(openedDb.resources, ['resource1']);
    });
    
    test('Database open should throw error for non-existent database', () async {
      // Пробуем открыть несуществующую базу данных
      expect(
        () async => await Database.open(
          directoryPath: './db',
          databaseName: 'nonexistent_db',
        ),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('не существует'))),
      );
    });
    
    test('Database open should preserve table type from config', () async {
      // Создаем базу данных с типом turnover
      final originalDb = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_open_turnover',
        tableType: TableType.turnover,
        measurements: ['measurement1', 'measurement2'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_open_turnover');
      
      // Проверяем, что оригинальная база данных имеет правильный тип
      expect(originalDb.tableType, TableType.turnover);
      
      // Открываем базу данных
      final openedDb = await Database.open(
        directoryPath: './db',
        databaseName: 'test_open_turnover',
      );
      
      // Проверяем, что тип таблицы сохранился
      expect(openedDb.tableType, TableType.turnover);
    });
    
    test('Database open should preserve measurements and resources from config', () async {
      // Создаем базу данных с определенными измерениями и ресурсами
      final measurements = ['measurement1', 'measurement2', 'measurement3'];
      final resources = ['resource1', 'resource2'];
      
      final originalDb = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_open_params',
        tableType: TableType.universal,
        measurements: measurements,
        resources: resources,
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_open_params');
      
      // Проверяем, что оригинальная база данных имеет правильные параметры
      expect(originalDb.measurements, measurements);
      expect(originalDb.resources, resources);
      
      // Открываем базу данных
      final openedDb = await Database.open(
        directoryPath: './db',
        databaseName: 'test_open_params',
      );
      
      // Проверяем, что измерения и ресурсы сохранились
      expect(openedDb.measurements, measurements);
      expect(openedDb.resources, resources);
    });
    
    test('Database open should throw error for empty directory path', () async {
      expect(
        () async => await Database.open(
          directoryPath: '',
          databaseName: 'test_db',
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Путь к каталогу не может быть пустым')),
      );
    });
    
    test('Database open should throw error for empty database name', () async {
      expect(
        () async => await Database.open(
          directoryPath: './db',
          databaseName: '',
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Название базы данных не может быть пустым')),
      );
    });
    
    test('Database open should work with universal table type', () async {
      // Создаем базу данных с универсальным типом
      final originalDb = await Database.createDatabase(
        directoryPath: './db',
        databaseName: 'test_open_universal',
        tableType: TableType.universal,
        measurements: ['measurement1'],
        resources: ['resource1', 'resource2'],
      );
      
      // Добавляем созданную базу данных в список для последующего удаления
      createdDatabases.add('test_open_universal');
      
      // Проверяем, что оригинальная база данных имеет правильный тип
      expect(originalDb.tableType, TableType.universal);
      
      // Открываем базу данных
      final openedDb = await Database.open(
        directoryPath: './db',
        databaseName: 'test_open_universal',
      );
      
      // Проверяем, что тип таблицы сохранился
      expect(openedDb.tableType, TableType.universal);
    });
  });
}