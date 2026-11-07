import 'dart:collection';

/// A bounded LRU cache.
///
/// [LinkedHashMap] preserves insertion order, so the least-recently-used entry
/// is always `keys.first`. Reading a key re-inserts it to move it to the back.
class Cache<K, V> {
  Cache(this.limit) : assert(limit > 0, 'limit must be positive');

  final int limit;

  final LinkedHashMap<K, V> _internal = LinkedHashMap<K, V>();

  int get length => _internal.length;

  bool containsKey(K key) => _internal.containsKey(key);

  void remove(K key) => _internal.remove(key);

  void clear() => _internal.clear();

  V? operator [](K key) {
    final val = _internal[key];

    if (val != null) {
      // Re-insert so this key becomes the most recently used.
      _internal
        ..remove(key)
        ..[key] = val;
    }

    return val;
  }

  void operator []=(K key, V val) {
    // Remove first so an existing key is re-inserted at the back rather than
    // keeping its old position.
    _internal
      ..remove(key)
      ..[key] = val;

    while (_internal.length > limit) {
      // Evict by KEY. `keys.first` is the least recently used entry.
      _internal.remove(_internal.keys.first);
    }
  }

  V doCache(K key, V Function() f) {
    final existing = this[key];
    if (existing != null) {
      return existing;
    }

    final val = f();
    this[key] = val;
    return val;
  }
}
