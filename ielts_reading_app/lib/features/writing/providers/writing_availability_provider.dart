import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/firebase/firebase_providers.dart';
import '../data/shared_writing_task_repository.dart';
import '../domain/models.dart';

part 'writing_availability_provider.g.dart';

/// Loads available (unseen) writing task counts per [WritingTaskType] for the current user.
///
/// Returns an empty map when the user is not logged in.
@riverpod
Future<Map<WritingTaskType, int>> writingAvailability(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  final repo = ref.watch(sharedWritingTaskRepositoryProvider);
  return repo.getAvailableCountsPerType(user.uid);
}
