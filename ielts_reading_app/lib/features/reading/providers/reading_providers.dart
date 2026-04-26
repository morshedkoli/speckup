import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/passage_repository.dart';
import '../data/shared_passage_repository.dart';
import '../domain/models.dart';
import '../../../services/firebase/firebase_providers.dart';

part 'reading_providers.g.dart';

// ─── Available question types ─────────────────────────────────────────────────

/// Fetches the question types that currently have passages in Firestore.
/// Returns a map of [QuestionType] → count of available passages.
@riverpod
Future<Map<QuestionType, int>> availableTypes(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    return ref
        .watch(sharedPassageRepositoryProvider)
        .getAvailableCountsPerType(user.uid);
  }

  return ref.watch(passageRepositoryProvider).getAvailableTypes();
}

// ─── Fetch passage for a type ─────────────────────────────────────────────────

/// Fetches a [PracticePassage] for the given [type] from Firestore.
@riverpod
Future<PracticePassage> passageByType(Ref ref, QuestionType type) async {
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    final passage = await ref
        .watch(sharedPassageRepositoryProvider)
        .getUnseenPassage(user.uid, type);
    if (passage == null) {
      throw Exception('No new passages available for ${type.name}.');
    }
    return passage;
  }

  return ref.watch(passageRepositoryProvider).getPassageForType(type);
}

// ─── Session state ────────────────────────────────────────────────────────────

/// Holds the in-progress practice session (answers, submission state).
/// Keyed by [QuestionType] so each type has its own session.
@riverpod
class PracticeSession extends _$PracticeSession {
  @override
  PracticeSessionState build(QuestionType type) {
    return const PracticeSessionState();
  }

  /// Call once the passage has been loaded and the session should start.
  void initPassage(PracticePassage passage) {
    if (state.passage != null) return; // already initialized
    state = PracticeSessionState(
      passage: passage,
      questionType: type,
      assignedAt: DateTime.now(),
    );
  }

  void setAnswer(String questionId, String answer) {
    if (state.isSubmitted) return;
    final updated = Map<String, String>.from(state.userAnswers);
    updated[questionId] = answer.trim();
    state = state.copyWith(userAnswers: updated);
  }

  /// Scores the session and marks it as submitted.
  Future<double> submitTest() async {
    if (state.passage == null || state.isSubmitted) return state.score;

    final passage = state.passage!;
    final questions = passage.questions;
    int correct = 0;
    for (final q in questions) {
      final given = state.userAnswers[q.id]?.toLowerCase().trim() ?? '';
      if (given == q.correctAnswer.toLowerCase().trim()) correct++;
    }

    final score = questions.isEmpty ? 0.0 : correct / questions.length;
    state = state.copyWith(
      isSubmitted: true,
      score: score,
      status: PracticeSessionStatus.completed,
      completedAt: DateTime.now(),
    );

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final repository = ref.read(sharedPassageRepositoryProvider);
      await repository.markSeen(user.uid, passage.id);
      await repository.markPassageUsed(passage.id);
    }

    return score;
  }

  /// Resets the session so the user can try a new passage.
  void reset() {
    state = const PracticeSessionState();
  }
}
