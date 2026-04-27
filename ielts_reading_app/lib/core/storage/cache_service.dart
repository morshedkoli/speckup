import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// A thin, TTL-aware cache that stores JSON-serialisable values in Hive.
///
/// Usage:
/// ```dart
/// final service = CacheService(HiveBoxes.cache);
///
/// // Write
/// await service.set('counts_user123', {'multipleChoice': 3, 'shortAnswer': 1},
///     ttl: const Duration(hours: 24));
///
/// // Read (returns null when missing or expired)
/// final data = service.get<Map<String, dynamic>>('counts_user123');
/// ```
class CacheService {
  final Box _box;

  CacheService(this._box);

  static const String _expiryPrefix = '__expiry__';

  /// Stores [value] under [key]. [value] must be JSON-encodable.
  ///
  /// Optionally set a [ttl] (time-to-live). If omitted the entry never expires.
  Future<void> set(
    String key,
    dynamic value, {
    Duration? ttl,
  }) async {
    final encoded = jsonEncode(value);
    await _box.put(key, encoded);
    if (ttl != null) {
      final expiry = DateTime.now().add(ttl).millisecondsSinceEpoch;
      await _box.put('$_expiryPrefix$key', expiry);
    }
  }

  /// Returns the cached value for [key], or `null` when missing / expired.
  T? get<T>(String key) {
    // Check expiry
    final expiryMs = _box.get('$_expiryPrefix$key') as int?;
    if (expiryMs != null &&
        DateTime.now().millisecondsSinceEpoch > expiryMs) {
      // Stale — delete silently in the background
      _box.delete(key);
      _box.delete('$_expiryPrefix$key');
      return null;
    }

    final raw = _box.get(key) as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as T;
    } catch (_) {
      return null;
    }
  }

  /// Returns true when a non-expired entry exists for [key].
  bool has(String key) => get(key) != null;

  /// Deletes the entry for [key].
  Future<void> delete(String key) async {
    await _box.delete(key);
    await _box.delete('$_expiryPrefix$key');
  }

  /// Clears all entries in this cache box.
  Future<void> clear() async => _box.clear();
}
