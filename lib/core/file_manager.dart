library;

import '../imports.dart';

/// Класс для управления файлами базы данных.
/// Инкапсулирует всю логику работы с файлами базы данных.
class FileManager {
  // Обязательные свойства базы данных
  final String directoryPath;
  final String databaseName;
  final TableType tableType;
  final List<String> measurements;
  final List<String> resources;
  final String databasePath;
  final int pageSize;
  final int extentSize;
  final int minReserveExtents;
  
  // Параметры логирования
  final Level logLevel;
  final String? logFilePath;
  final int maxLogFileSize; // в байтах
  final int maxLogFilesCount; // количество файлов для ротации

  // Логгер
  static final Logger _logger = Logger('FileManager');

  /// Конструктор класса FileManager
  FileManager({
    required this.directoryPath,
    required this.databaseName,
    required this.tableType,
    required this.measurements,
    required this.resources,
    required this.logLevel,
    required this.logFilePath,
    required this.maxLogFileSize,
    required this.maxLogFilesCount,
    required this.pageSize,
    required this.extentSize,
    required this.minReserveExtents,
  }) : databasePath = '$directoryPath/$databaseName';

  /// Инициализация конкретной базы данных
  Future<void> initDatabase() async {
    if (!await databaseExists()) {
      await createDatabaseDirectory();
    }
    await allocateDatabaseFiles();
  }

  /// Разметка файлов под базу данных
  Future<void> allocateDatabaseFiles() async {
    _logger.fine('Подготовим файлы таблиц');
    // Размечаем файлы под базу данных согласно параметрам
    await _markDatabaseFiles();

    _logger.info('Файлы таблиц данных подготовлены');
  }

  /// Разметка файлов базы данных для инициализации структуры хранения данных
  Future<void> _markDatabaseFiles() async {
    _logger.info('Начинаем разметку файлов базы данных "$databaseName"');
    _logger.info('Параметры: размер страницы $pageSize байт, размер экстента $extentSize байт, '
        'минимальное количество зарезервированных экстентов: $minReserveExtents');
    
    // Резервируем дисковое пространство для файлов таблиц
    await _reserveDiskSpace();

    try {
      // Создаем заголовки файлов с информацией о структуре БД
      final headerInfo = {
        'databaseName': databaseName,
        'pageSize': pageSize,
        'extentSize': extentSize,
        'minReserveExtents': minReserveExtents,
        'created': DateTime.now().toIso8601String(),
        'version': '1.0.0'
      };

      // Проверяем существующие файлы и записываем заголовок только в те, которые существуют
      final movementsPath = '$databasePath/$databaseName.movements';
      final aggregationsPath = '$databasePath/$databaseName.aggregations';
      final turnoversPath = '$databasePath/$databaseName.turnovers';
      
      // Проверяем и записываем заголовок в файл движений, если он существует
      final movementsFile = File(movementsPath);
      if (await movementsFile.exists()) {
        await writeHeaderToFile(movementsPath, headerInfo);
      }
      
      // Проверяем и записываем заголовок в файл агрегаций, если он существует
      final aggregationsFile = File(aggregationsPath);
      if (await aggregationsFile.exists()) {
        await writeHeaderToFile(aggregationsPath, headerInfo);
      }
      
      // Проверяем и записываем заголовок в файл оборотов, если он существует
      final turnoversFile = File(turnoversPath);
      if (await turnoversFile.exists()) {
        await writeHeaderToFile(turnoversPath, headerInfo);
      }

      _logger.info('Файлы базы данных успешно размечены и заголовки записаны');
    } catch (error, stackTrace) {
      _logger.severe('Ошибка при разметке файлов базы данных: $error', error, stackTrace);
      rethrow;
    }
 }

   /// Резервирование дискового пространства для файлов таблиц
   Future<void> _reserveDiskSpace() async {
     _logger.fine('Резервируем дисковое пространство для файлов таблиц');
     try {
       // Получаем пути к файлам таблиц
       final movementsPath = '$databasePath/$databaseName.movements';
       final aggregationsPath = '$databasePath/$databaseName.aggregations';
       final turnoversPath = '$databasePath/$databaseName.turnovers';
       
       // Увеличиваем размер файлов таблиц (только если файлы существуют)
       await _increaseFileSizeIfExists(movementsPath);
       await _increaseFileSizeIfExists(aggregationsPath);
       await _increaseFileSizeIfExists(turnoversPath);
       
       _logger.info('Дисковое пространство успешно зарезервировано');
     } catch (error, stackTrace) {
       _logger.severe('Ошибка при резервировании дискового пространства: $error', error, stackTrace);
       rethrow;
     }
  }

  /// Увеличение размера файла до целевого размера
  Future<void> _increaseFileSizeTarget(File file) async {
    // Рассчитываем размер резерва: минимальное количество экстентов * размер экстента
    final reserveSize = minReserveExtents * extentSize;
    _logger.fine('Размер резерва: $reserveSize байт');
    try {
      final currentSize = await _getFileSize(file);
      _logger.fine('Текущий размер файла: $currentSize байт');
      if (currentSize < reserveSize) {
        _logger.fine('Увеличиваем размер файла до $reserveSize байт');
        final RandomAccessFile randomAccessFile = await file.open(mode: FileMode.write);
        await randomAccessFile.truncate(reserveSize);
        await randomAccessFile.close();
        final newSize = await _getFileSize(file);
        _logger.fine('Размер файла увеличен до $newSize байт (ожидалось $reserveSize)');
      } else {
        _logger.fine('Файл уже имеет достаточный размер: $currentSize байт');
      }
    } catch (error, stackTrace) {
      _logger.severe('Ошибка при увеличении размера файла: $error', error, stackTrace);
      rethrow;
    }
 }

  /// Увеличение размера файла до указанного размера, если файл существует
 Future<void> _increaseFileSizeIfExists(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await _increaseFileSizeTarget(file);
      } else {
        _logger.fine('Файл $filePath не существует, пропускаем увеличение размера');
      }
    } catch (error, stackTrace) {
      _logger.severe('Ошибка при проверке существования файла $filePath: $error', error, stackTrace);
      rethrow;
    }
 }

  /// Получение размера файла
  Future<int> _getFileSize(File file) async {
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Проверка существования базы данных по указанному пути
 Future<bool> databaseExists() async {
    final dir = Directory(databasePath);
    return await dir.exists();
 }

  /// Создание директории базы данных
  Future<void> createDatabaseDirectory() async {
    final dir = Directory(databasePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
 }

   /// Запись заголовка в указанный файл
  Future<void> writeHeaderToFile(String filePath, Map<String, dynamic> headerInfo) async {
     // Формируем заголовок в специальном текстовом формате для легкого отделения от данных
     final headerLines = [
       '// DATABASE HEADER',
       '// Generated: ${DateTime.now().toIso8601String()}',
       '// Version: 1.0.0',
       ...headerInfo.entries.map((entry) => '${entry.key}: ${entry.value}'),
       '// END HEADER',
       ''
     ];
     
     final headerContent = headerLines.join('\n');
     
     File file = File(filePath);
     // Проверяем, существует ли файл
     final fileExists = await file.exists();
     
     // Записываем заголовок в файл
     if (!fileExists) {
       // Если файл не существует, создаем его с заголовком
       await file.writeAsString(headerContent);
       _logger.fine('Создан новый файл с заголовком: ${file.path}');
     } else {
       // Для существующего файла проверяем, есть ли уже заголовок
       // Считываем текущее содержимое
       final currentContent = await file.readAsString();
       
       // Проверяем, есть ли уже заголовок в файле (по наличию специального маркера)
       // Используем более точную проверку, чтобы избежать проблем с пробелами
       final trimmedContent = currentContent.trimLeft();
       if (trimmedContent.startsWith('// DATABASE HEADER')) {
         _logger.fine('Заголовок уже существует в файле: ${file.path}');
         return;
       } else {
         // Записываем новый контент с заголовком в начало
         await file.writeAsString(headerContent + currentContent);
         _logger.fine('Заголовок добавлен в существующий файл: ${file.path}');
       }
     }
     
     _logger.fine('Заголовок записан в файл: ${file.path}');
   }
}