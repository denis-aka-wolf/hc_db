library;

import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';

/// Класс для управления логированием в базе данных
class DatabaseLogger {
  // Параметры логирования
  final Level logLevel;
  final String? logFilePath;
  final int maxLogFileSize; // в байтах
  final int maxLogFilesCount; // количество файлов для ротации

  // Логгер
  static final Logger _logger = Logger('DatabaseLogger');
  StreamSubscription<LogRecord>? _logSubscription;
  File? _logFile;
  IOSink? _logSink;

  DatabaseLogger({
    this.logLevel = Level.INFO,
    this.logFilePath,
    this.maxLogFileSize = 10485760, // 10MB
    this.maxLogFilesCount = 5,
  });

  /// Настраивает логирование в файл
  Future<void> setupFileLogging() async {
    // Устанавливаем уровень логирования
    Logger.root.level = logLevel;
    
    // Если указан путь к файлу логов, настраиваем запись в файл
    if (logFilePath != null && logFilePath!.isNotEmpty) {
      try {
        // Создаем директорию для логов, если она не существует
        final logDir = Directory(logFilePath!).parent;
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }
         
        // Создаем файл лога
        _logFile = File(logFilePath!);
         
        // Проверяем, нужно ли выполнить ротацию логов
        await _rotateLogFilesIfNeeded();
         
        // Открываем файл для записи
        _logSink = _logFile!.openWrite(mode: FileMode.append);
         
        // Подписываемся на события логирования
        _logSubscription = Logger.root.onRecord.listen((LogRecord record) {
          String logLine = _formatLogRecord(record);
          _logSink?.write(logLine);
        });
         
        _logger.info('Логирование в файл настроено: ${logFilePath!}');
      } catch (e) {
        _logger.severe('Ошибка при настройке логирования в файл: $e');
      }
    } else {
      // Если путь к файлу не указан, используем только консольное логирование
      _logSubscription = Logger.root.onRecord.listen((LogRecord record) {
        print(_formatLogRecord(record));
      });
    }
  }
   
  /// Форматирует запись лога
  String _formatLogRecord(LogRecord record) {
    String prefix = '${record.time.toIso8601String()} [${record.level.name}] ${record.loggerName}';
    if (record.zone != null) {
      prefix += ' ${record.zone}';
    }
    String message = '${prefix}: ${record.message}';
    if (record.error != null) {
      message += '\n${record.error}';
    }
    if (record.stackTrace != null) {
      message += '\n${record.stackTrace}';
    }
    return '$message\n';
  }
   
  /// Выполняет ротацию файлов логов при необходимости
  Future<void> _rotateLogFilesIfNeeded() async {
    if (_logFile == null) return;
    
    try {
      // Проверяем размер текущего файла лога
      int fileSize = await _logFile!.length();
      
      if (fileSize > maxLogFileSize) {
        // Выполняем ротацию логов
        await _rotateLogFiles();
      }
    } catch (e) {
      _logger.warning('Не удалось проверить размер файла лога: $e');
    }
 }
   
  /// Выполняет ротацию файлов логов
  Future<void> _rotateLogFiles() async {
    if (_logFile == null) return;
    
    try {
      // Закрываем текущий файл лога
      await _logSink?.flush();
      await _logSink?.close();
       
      // Переименовываем текущий файл лога с добавлением даты/времени
      String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      String rotatedLogPath = '${logFilePath!}.$timestamp';
      File rotatedLogFile = File(rotatedLogPath);
      
      // Переименовываем текущий файл
      await _logFile!.rename(rotatedLogPath);
      
      // Удаляем старые файлы логов, если их больше максимального количества
      await _cleanupOldLogFiles();
      
      // Создаем новый файл лога с исходным именем
      _logFile = File(logFilePath!);
      
      // Открываем новый файл лога
      _logSink = _logFile!.openWrite(mode: FileMode.write);
       
      _logger.info('Файл лога ротирован: $rotatedLogPath');
    } catch (e) {
      _logger.severe('Ошибка при ротации файлов лога: $e');
    }
  }
   
  /// Удаляет старые файлы логов
  Future<void> _cleanupOldLogFiles() async {
    if (logFilePath == null) return;
     
    try {
      Directory logDir = File(logFilePath!).parent;
      if (!await logDir.exists()) return;
      
      // Получаем список файлов логов
      List<FileSystemEntity> files = await logDir
          .list()
          .where((file) => file.path.startsWith(logFilePath!) && file.path.contains('.'))
          .toList();
       
      // Сортируем файлы по времени модификации (в порядке убывания)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
       
      // Удаляем лишние файлы, оставляя только maxLogFilesCount
      for (int i = maxLogFilesCount; i < files.length; i++) {
        try {
          await files[i].delete();
          _logger.fine('Удален старый файл лога: ${files[i].path}');
        } catch (e) {
          _logger.warning('Не удалось удалить старый файл лога ${files[i].path}: $e');
        }
      }
    } catch (e) {
      _logger.severe('Ошибка при очистке старых файлов лога: $e');
    }
 }
   
  /// Закрывает логирование и освобождает ресурсы
  Future<void> closeLogging() async {
    try {
      await _logSubscription?.cancel();
      await _logSink?.flush();
      await _logSink?.close();
    } catch (e) {
      _logger.severe('Ошибка при закрытии логирования: $e');
    }
  }
}