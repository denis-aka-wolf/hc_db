library;

import 'dart:async';

// Элемент кэша
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry(this.data, this.timestamp, this.ttl);

  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

// Система кэширования
class Cache {
  final Map<String, CacheEntry<dynamic>> _cache = {};
  final List<String> _accessOrder = [];
  final Duration _defaultTtl;
  int _maxSize;

  Cache({Duration? defaultTtl, int maxSize = 1000})
      : _defaultTtl = defaultTtl ?? const Duration(hours: 1),
        _maxSize = maxSize;

  // Инициализация кэша
  Future<void> init() async {
    print('Кэш инициализирован');
  }

  // Получение данных из кэша
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }
    
    if (entry.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return null;
    }
    
    // Обновляем порядок доступа (LRU)
    _accessOrder.remove(key);
    _accessOrder.add(key);
    
    return entry.data as T;
  }

  // Добавление данных в кэш
  void put<T>(String key, T data, {Duration? ttl}) {
    final entryTtl = ttl ?? _defaultTtl;
    final entry = CacheEntry(data, DateTime.now(), entryTtl);
    _cache[key] = entry;
    
    // Обновляем порядок доступа
    _accessOrder.remove(key);
    _accessOrder.add(key);
    
    // Проверяем размер кэша
    if (_cache.length > _maxSize) {
      // Удаляем самый старый элемент (LRU)
      final oldestKey = _accessOrder.first;
      _cache.remove(oldestKey);
      _accessOrder.removeAt(0);
    }
  }

  // Удаление данных из кэша
  void remove(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  // Очистка кэша
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  // Получение размера кэша
  int get size => _cache.length;
}