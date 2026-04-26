import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../progress/data/history_repository.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../data/practice_assignment_repository.dart';
import '../data/shared_passage_repository.dart';
import '../domain/models.dart';

part 'practice_provider.g.dart';

// ─── Session controller ───────────────────────────────────────────────────────

@riverpod
class PracticeSessionController extends _$PracticeSessionController {
  @override
  PracticeSessionState build() {
    return const PracticeSessionState();
  }

  /// Start a new practice session for [type].
  ///
  /// Priority:
  ///   1. Resume an already-assigned (incomplete) session from local cache or Firestore.
  ///   2. Fetch an unseen passage from the admin's shared pool.
  ///   3. Throw if no unseen passages are available.
  Future<void> startSession(QuestionType type) async {
    final user = ref.read(currentUserProvider);
    final userKey = user?.uid ?? 'guest';
    final sharedRepo = ref.read(sharedPassageRepositoryProvider);
    final assignmentRepo = ref.read(practiceAssignmentRepositoryProvider);

    // Don't restart an in-progress session for the same type
    if (state.passage != null &&
        state.questionType == type &&
        !state.isCompleted) {
      return;
    }

    // 1. Resume an existing assigned session
    final assignedSession = await assignmentRepo.getAssignedSession(
      userKey: userKey,
      uid: user?.uid,
      type: type,
    );
    if (assignedSession != null && !assignedSession.isCompleted) {
      state = assignedSession;
      return;
    }

    // 2. Fetch an unseen passage from the admin's shared pool
    PracticePassage? selectedPassage;
    if (user != null) {
      selectedPassage = await sharedRepo.getUnseenPassage(user.uid, type);
    }

    if (selectedPassage == null) {
      throw Exception(
        'No new passages available for this type. '
        'The admin is adding more — please check back later.',
      );
    }

    final session = PracticeSessionState(
      passage: selectedPassage,
      questionType: type,
      assignedAt: DateTime.now(),
      status: PracticeSessionStatus.assigned,
    );
    state = session;

    // 3. Persist assignment so the user can resume it
    await assignmentRepo.assignSession(
      userKey: userKey,
      uid: user?.uid,
      session: session,
    );

    // 4. Reserve the passage for this user — won't be served again
    if (user != null) {
      unawaited(sharedRepo.markSeen(user.uid, selectedPassage.id));
    }
  }

  void setAnswer(String questionId, String answer) {
    if (state.isSubmitted) return;

    final newAnswers = Map<String, String>.from(state.userAnswers);
    newAnswers[questionId] = answer.trim();
    state = state.copyWith(userAnswers: newAnswers);

    if (state.passage != null) {
      final user = ref.read(currentUserProvider);
      final userKey = user?.uid ?? 'guest';
      unawaited(
        ref.read(practiceAssignmentRepositoryProvider).saveLocalProgress(
              userKey: userKey,
              session: state,
            ),
      );
    }
  }

  Future<void> submitTest() async {
    if (state.passage == null || state.isSubmitted) return;

    int correctCount = 0;
    for (var q in state.passage!.questions) {
      final userAnswer = state.userAnswers[q.id]?.toLowerCase().trim() ?? '';
      final correctAnswer = q.correctAnswer.toLowerCase().trim();
      if (userAnswer == correctAnswer) correctCount++;
    }

    final percentage = state.passage!.questions.isEmpty
        ? 0.0
        : correctCount / state.passage!.questions.length;

    final completedState = state.copyWith(
      isSubmitted: true,
      score: percentage,
      status: PracticeSessionStatus.completed,
      completedAt: DateTime.now(),
    );
    state = completedState;

    final user = ref.read(currentUserProvider);
    final userKey = user?.uid ?? 'guest';

    // Save result to user history
    if (user != null) {
      final repository = ref.read(historyRepositoryProvider);
      await repository.savePracticeSession(user.uid, state);
    }

    // Mark assignment complete (local + Firestore)
    await ref.read(practiceAssignmentRepositoryProvider).markCompleted(
          userKey: userKey,
          uid: user?.uid,
          session: completedState,
        );

    // Stamp lastUsedAt on the shared passage so the admin can see utilisation
    final passageId = completedState.passage?.id;
    if (passageId != null) {
      unawaited(
        ref.read(sharedPassageRepositoryProvider).markPassageUsed(passageId),
      );
    }
  }
}
