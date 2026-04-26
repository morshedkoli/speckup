import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firebase_providers.dart';
import '../domain/models.dart';

class WritingHistoryRepository {
  WritingHistoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> saveWritingSession(
      String uid, WritingSessionState session) async {
    if (session.task == null || session.evaluation == null) return;

    final task = session.task!;
    final evaluation = session.evaluation!;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('writing_history')
        .add({
      'timestamp': FieldValue.serverTimestamp(),
      'taskId': task.id,
      'taskType': task.taskType.name,
      'title': task.title,
      'difficulty': task.difficulty,
      'estimatedMinutes': task.estimatedMinutes,
      'minWords': task.minWords,
      'prompt': task.prompt,
      'userResponse': session.userResponse,
      'wordCount': session.wordCount,
      'overallBand': evaluation.overallBand,
      'summary': evaluation.summary,
      'criteria':
          evaluation.criteria.map((criterion) => criterion.toMap()).toList(),
      'strengths': evaluation.strengths,
      'improvements': evaluation.improvements,
      'modelAnswer': evaluation.modelAnswer,
    });
  }

  Stream<List<Map<String, dynamic>>> getUserHistory(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('writing_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}

final writingHistoryRepositoryProvider =
    Provider<WritingHistoryRepository>((ref) {
  return WritingHistoryRepository(FirebaseFirestore.instance);
});

final userWritingHistoryStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return ref.watch(writingHistoryRepositoryProvider).getUserHistory(user.uid);
});
