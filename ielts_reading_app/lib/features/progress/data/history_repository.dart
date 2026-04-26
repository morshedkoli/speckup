import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/firebase/firebase_providers.dart';
import '../../reading/domain/models.dart';

part 'history_repository.g.dart';

class HistoryRepository {
  final FirebaseFirestore _firestore;

  HistoryRepository(this._firestore);

  Future<void> savePracticeSession(String uid, PracticeSessionState session) async {
    if (session.passage == null) return;

    final passage = session.passage!;
    
    final data = {
      'timestamp': FieldValue.serverTimestamp(),
      'passageId': passage.id,
      'title': passage.title,
      'difficulty': passage.difficulty,
      'score': session.score,
      'questionCount': passage.questions.length,
      'questions': passage.questions.map((q) => {
        'id': q.id,
        'type': q.type.name,
        'text': q.text,
        'correctAnswer': q.correctAnswer,
        'userAnswer': session.userAnswers[q.id] ?? '',
        'isCorrect': (session.userAnswers[q.id]?.toLowerCase() ?? '') == q.correctAnswer.toLowerCase(),
      }).toList(),
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('history')
        .add(data);
  }

  Stream<List<Map<String, dynamic>>> getUserHistory(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}

@riverpod
HistoryRepository historyRepository(Ref ref) {
  return HistoryRepository(FirebaseFirestore.instance);
}

@riverpod
Stream<List<Map<String, dynamic>>> userHistoryStream(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  return ref.watch(historyRepositoryProvider).getUserHistory(user.uid);
}
