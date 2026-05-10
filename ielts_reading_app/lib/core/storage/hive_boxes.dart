import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_service.dart';

class HiveBoxes {
  HiveBoxes._();

  static const _sessionBoxName = 'speakup_sessions';

  /// General-purpose TTL cache (availability counts, etc.)
  static const _cacheBoxName = 'speakup_cache';
  static const _offlineBoxName = 'speakup_offline';
  static const _syncQueueBoxName = 'speakup_sync_queue';
  static const _progressBoxName = 'speakup_progress';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_sessionBoxName);
    await Hive.openBox(_cacheBoxName);
    await Hive.openBox(_offlineBoxName);
    await Hive.openBox(_syncQueueBoxName);
    await Hive.openBox(_progressBoxName);
  }

  static Box get session => Hive.box(_sessionBoxName);
  static Box get cache => Hive.box(_cacheBoxName);
  static Box get offline => Hive.box(_offlineBoxName);
  static Box get syncQueue => Hive.box(_syncQueueBoxName);
  static Box get progress => Hive.box(_progressBoxName);
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService(HiveBoxes.cache);
});
