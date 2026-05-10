import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/cache_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../domain/models.dart';

class SharedWritingTaskRepository {
  SharedWritingTaskRepository(this._firestore, this._cache);

  final FirebaseFirestore _firestore;
  final CacheService _cache;

  static const _countsCacheTtl = Duration(hours: 24);

  Future<void> saveTask(WritingTask task) async {
    await _firestore.collection('shared_writing_tasks').doc(task.id).set({
      ...task.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));
  }

  Future<void> markSeen(String uid, String taskId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('seen_writing_tasks')
        .doc(taskId)
        .set({'seenAt': FieldValue.serverTimestamp()});

    // Invalidate cached counts
    await _cache.delete(_countsKey(uid));
  }

  Future<void> markTaskUsed(String taskId) async {
    try {
      await _firestore
          .collection('shared_writing_tasks')
          .doc(taskId)
          .update({'lastUsedAt': FieldValue.serverTimestamp()});
    } catch (_) {
      // Non-critical — don't surface to the user
    }
  }

  String _countsKey(String uid) => 'writing_task_counts_$uid';

  Future<Set<String>> _getSeenIds(String uid) async {
    try {
      // Use Source.cache first to avoid a cold read every time
      try {
        final snap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('seen_writing_tasks')
            .get(const GetOptions(source: Source.cache));
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((doc) => doc.id).toSet();
        }
      } catch (_) {
        // Cache miss
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('seen_writing_tasks')
          .get(const GetOptions(source: Source.serverAndCache));
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (_) {
      // First-time user may not have this subcollection yet
      return <String>{};
    }
  }

  Future<List<WritingTaskType>> getTypesNeedingTasks(String uid) async {
    final seenIds = await _getSeenIds(uid);
    final needed = <WritingTaskType>[];

    for (final type in WritingTaskType.values) {
      final snapshot = await _firestore
          .collection('shared_writing_tasks')
          .where('taskType', isEqualTo: type.name)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));

      final hasUnseen = snapshot.docs.any((doc) => !seenIds.contains(doc.id));
      if (!hasUnseen) {
        needed.add(type);
      }
    }

    return needed;
  }

  Future<Map<WritingTaskType, int>> getAvailableCountsPerType(
      String uid) async {
    // 1. Check cache
    final cached = _cache.get<Map<String, dynamic>>(_countsKey(uid));
    if (cached != null) {
      return cached.map(
        (k, v) => MapEntry(
            WritingTaskType.values.firstWhere((e) => e.name == k),
            (v as num).toInt()),
      );
    }

    // 2. Fetch from Firestore
    final seenIds = await _getSeenIds(uid);
    final counts = <WritingTaskType, int>{};

    for (final type in WritingTaskType.values) {
      final snapshot = await _firestore
          .collection('shared_writing_tasks')
          .where('taskType', isEqualTo: type.name)
          .limit(250)
          .get(const GetOptions(source: Source.serverAndCache));

      final unseen = snapshot.docs.where((d) => !seenIds.contains(d.id)).length;
      counts[type] = unseen;
    }

    // 3. Write-through to Hive
    await _cache.set(
      _countsKey(uid),
      counts.map((k, v) => MapEntry(k.name, v)),
      ttl: _countsCacheTtl,
    );

    return counts;
  }

  Future<WritingTask?> getUnseenTask(String uid, WritingTaskType type) async {
    final seenIds = await _getSeenIds(uid);
    final snapshot = await _firestore
        .collection('shared_writing_tasks')
        .where('taskType', isEqualTo: type.name)
        .limit(100)
        .get(const GetOptions(source: Source.serverAndCache));

    for (final doc in snapshot.docs) {
      if (!seenIds.contains(doc.id)) {
        try {
          return WritingTask.fromMap(doc.data());
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }
}

final sharedWritingTaskRepositoryProvider =
    Provider<SharedWritingTaskRepository>((ref) {
  return SharedWritingTaskRepository(
    FirebaseFirestore.instance,
    CacheService(HiveBoxes.cache),
  );
});
