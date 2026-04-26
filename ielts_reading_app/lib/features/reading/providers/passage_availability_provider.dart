import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/firebase/firebase_providers.dart';
import '../data/shared_passage_repository.dart';
import '../domain/models.dart';

part 'passage_availability_provider.g.dart';

/// Loads available (unseen) passage counts per [QuestionType] for the current user.
///
/// Returns an empty map when the user is not logged in.
@riverpod
Future<Map<QuestionType, int>> passageAvailability(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  final repo = ref.watch(sharedPassageRepositoryProvider);
  return repo.getAvailableCountsPerType(user.uid);
}
