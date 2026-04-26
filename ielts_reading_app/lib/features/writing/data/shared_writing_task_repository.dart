import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';

class SharedWritingTaskRepository {
  SharedWritingTaskRepository(this._firestore);

  final FirebaseFirestore _firestore;

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

  Future<Set<String>> _getSeenIds(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('seen_writing_tasks')
        .get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  Future<List<WritingTaskType>> getTypesNeedingTasks(String uid) async {
    final seenIds = await _getSeenIds(uid);
    final needed = <WritingTaskType>[];

    for (final type in WritingTaskType.values) {
      final snapshot = await _firestore
          .collection('shared_writing_tasks')
          .where('taskType', isEqualTo: type.name)
          .orderBy('createdAt')
          .limit(50)
          .get();

      final hasUnseen = snapshot.docs.any((doc) => !seenIds.contains(doc.id));
      if (!hasUnseen) {
        needed.add(type);
      }
    }

    return needed;
  }

  Future<Map<WritingTaskType, int>> getAvailableCountsPerType(String uid) async {
    final seenIds = await _getSeenIds(uid);
    final counts = <WritingTaskType, int>{};

    for (final type in WritingTaskType.values) {
      final snapshot = await _firestore
          .collection('shared_writing_tasks')
          .where('taskType', isEqualTo: type.name)
          .orderBy('createdAt')
          .limit(250)
          .get();
      
      final unseen = snapshot.docs.where((d) => !seenIds.contains(d.id)).length;
      counts[type] = unseen;
    }
    return counts;
  }

  Future<WritingTask?> getUnseenTask(String uid, WritingTaskType type) async {
    final seenIds = await _getSeenIds(uid);
    final snapshot = await _firestore
        .collection('shared_writing_tasks')
        .where('taskType', isEqualTo: type.name)
        .orderBy('createdAt')
        .limit(100)
        .get();

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
  return SharedWritingTaskRepository(FirebaseFirestore.instance);
});
