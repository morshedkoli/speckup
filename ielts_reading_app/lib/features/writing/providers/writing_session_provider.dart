import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firebase_providers.dart';
import '../data/shared_writing_task_repository.dart';
import '../data/writing_assignment_repository.dart';
import '../data/writing_history_repository.dart';
import '../domain/models.dart';

class WritingSessionController extends Notifier<WritingSessionState> {
  @override
  WritingSessionState build() {
    return const WritingSessionState();
  }

  Future<void> startSession(WritingTaskType type) async {
    final user = ref.read(currentUserProvider);
    final userKey = user?.uid ?? 'guest';
    final sharedRepo = ref.read(sharedWritingTaskRepositoryProvider);
    final assignmentRepo = ref.read(writingAssignmentRepositoryProvider);

    if (state.task != null && state.taskType == type && !state.isCompleted) {
      return;
    }

    final assignedSession = await assignmentRepo.getAssignedSession(
      userKey: userKey,
      uid: user?.uid,
      type: type,
    );
    if (assignedSession != null && !assignedSession.isCompleted) {
      state = assignedSession;
      return;
    }

    WritingTask? selectedTask;
    if (user != null) {
      selectedTask = await sharedRepo.getUnseenTask(user.uid, type);
    }

    if (selectedTask == null) {
      throw Exception('No new writing tasks available. Please check back later.');
    }

    final session = WritingSessionState(
      task: selectedTask,
      taskType: type,
      assignedAt: DateTime.now(),
      status: WritingSessionStatus.assigned,
    );
    state = session;

    await assignmentRepo.assignSession(
      userKey: userKey,
      uid: user?.uid,
      session: session,
    );
    if (user != null) {
      unawaited(sharedRepo.markSeen(user.uid, selectedTask.id));
    }
  }

  void updateResponse(String response) {
    if (state.isSubmitted) return;

    state = state.copyWith(userResponse: response);

    if (state.task != null) {
      final user = ref.read(currentUserProvider);
      final userKey = user?.uid ?? 'guest';
      unawaited(
        ref.read(writingAssignmentRepositoryProvider).saveLocalProgress(
              userKey: userKey,
              session: state,
            ),
      );
    }
  }

  Future<void> submitWriting() async {
    if (state.task == null || state.isSubmitted) return;

    final completedState = state.copyWith(
      isSubmitted: true,
      status: WritingSessionStatus.completed,
      completedAt: DateTime.now(),
    );
    state = completedState;

    final user = ref.read(currentUserProvider);
    final userKey = user?.uid ?? 'guest';

    if (user != null) {
      await ref
          .read(writingHistoryRepositoryProvider)
          .saveWritingSession(user.uid, completedState);
    }

    await ref.read(writingAssignmentRepositoryProvider).markCompleted(
          userKey: userKey,
          uid: user?.uid,
          session: completedState,
        );

  }

  void clearSession() {
    state = const WritingSessionState();
  }
}

final writingSessionControllerProvider =
    NotifierProvider<WritingSessionController, WritingSessionState>(
  WritingSessionController.new,
);
