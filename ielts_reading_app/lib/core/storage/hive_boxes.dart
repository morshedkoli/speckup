import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_service.dart';

class HiveBoxes {
  HiveBoxes._();

  static const _sessionBoxName = 'speakup_sessions';

  /// General-purpose TTL cache (availability counts, etc.)
  static const _cacheBoxName = 'speakup_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_sessionBoxName);
    await Hive.openBox(_cacheBoxName);
  }

  static Box get session => Hive.box(_sessionBoxName);
  static Box get cache  => Hive.box(_cacheBoxName);
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService(HiveBoxes.cache);
});
