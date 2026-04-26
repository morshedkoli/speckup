import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../domain/diagnostic_models.dart';

part 'diagnostic_repository.g.dart';

class DiagnosticRepository {
  final FirebaseFirestore _firestore;

  DiagnosticRepository(this._firestore);

  Future<DiagnosticState?> getRandomDiagnostic() async {
    try {
      final snapshot = await _firestore
          .collection('shared_diagnostic_passages')
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final docs = [...snapshot.docs]..shuffle();
      for (final doc in docs) {
        try {
          final data = doc.data();
          final rawQuestions = data['questions'];
          if (rawQuestions is! List || rawQuestions.isEmpty) continue;

          return DiagnosticState(
            passage: DiagnosticPassage.fromMap(doc.id, data),
            questions: rawQuestions
                .asMap()
                .entries
                .map(
                  (entry) => DiagnosticQuestion.fromMap(
                    Map<String, dynamic>.from(entry.value as Map),
                    entry.key,
                  ),
                )
                .where(
                  (question) =>
                      question.questionText.isNotEmpty &&
                      question.options.isNotEmpty &&
                      question.correctAnswer.isNotEmpty,
                )
                .toList(),
          );
        } catch (_) {
          continue;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Stream<bool> watchDiagnosticCompleted(String uid) async* {
    yield isDiagnosticCompletedLocally(uid);

    try {
      await for (final doc
          in _firestore.collection('users').doc(uid).snapshots()) {
        final data = doc.data();
        final completed = data?['diagnosticCompleted'] == true;
        if (completed) {
          await _saveDiagnosticCompletedLocally(uid);
        }
        yield completed || isDiagnosticCompletedLocally(uid);
      }
    } catch (_) {
      yield isDiagnosticCompletedLocally(uid);
    }
  }

  Future<void> markDiagnosticCompleted({
    required String uid,
    required double estimatedBandScore,
  }) async {
    await _saveDiagnosticCompletedLocally(
      uid,
      estimatedBandScore: estimatedBandScore,
    );

    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'diagnosticCompleted': true,
          'diagnosticBandScore': estimatedBandScore,
          'diagnosticCompletedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Local completion unlocks the app even if deployed Firestore rules are stale.
    }
  }

  bool isDiagnosticCompletedLocally(String uid) {
    return HiveBoxes.session.get(_completionKey(uid)) == true;
  }

  Future<void> _saveDiagnosticCompletedLocally(
    String uid, {
    double? estimatedBandScore,
  }) async {
    await HiveBoxes.session.put(_completionKey(uid), true);
    if (estimatedBandScore != null) {
      await HiveBoxes.session.put(_scoreKey(uid), estimatedBandScore);
    }
  }

  String _completionKey(String uid) {
    return 'diagnostic.completed.$uid';
  }

  String _scoreKey(String uid) {
    return 'diagnostic.band_score.$uid';
  }
}

@riverpod
DiagnosticRepository diagnosticRepository(Ref ref) {
  return DiagnosticRepository(FirebaseFirestore.instance);
}

@riverpod
Stream<bool> diagnosticCompleted(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);

  return ref
      .watch(diagnosticRepositoryProvider)
      .watchDiagnosticCompleted(user.uid);
}
