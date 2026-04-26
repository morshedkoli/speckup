import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models.dart';

part 'passage_repository.g.dart';

/// Fetches reading passages directly from the `shared_passages` Firestore
/// collection. No seen-tracking, no assignment logic — clean and simple.
class PassageRepository {
  final FirebaseFirestore _db;

  PassageRepository(this._db);

  // ─── Types available in the database ────────────────────────────────────────

  /// Returns the set of [QuestionType]s that have at least one passage in
  /// Firestore, together with the count of passages for each type.
  Future<Map<QuestionType, int>> getAvailableTypes() async {
    final snapshot = await _db.collection('shared_passages').get();

    final counts = <QuestionType, int>{};
    for (final doc in snapshot.docs) {
      final type = _readQuestionType(doc.data());
      if (type == null) continue;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  // ─── Fetch a passage for a given type ────────────────────────────────────────

  /// Returns a single passage of [type] from Firestore.
  /// Queries `questionType` first; falls back to `type` for legacy docs.
  Future<PracticePassage> getPassageForType(QuestionType type) async {
    // First try the canonical field name
    var snapshot = await _db
        .collection('shared_passages')
        .where('questionType', isEqualTo: type.name)
        .limit(20)
        .get();

    // Fall back to legacy `type` field if nothing found
    if (snapshot.docs.isEmpty) {
      snapshot = await _db
          .collection('shared_passages')
          .where('type', isEqualTo: type.name)
          .limit(20)
          .get();
    }

    // Last-resort compatibility for admin-created legacy docs that are visible
    // in the dashboard but missing both top-level type fields.
    if (snapshot.docs.isEmpty) {
      final allDocs = await _db.collection('shared_passages').limit(250).get();
      for (final doc in allDocs.docs) {
        if (_readQuestionType(doc.data()) != type) continue;
        try {
          return _fromFirestore(doc.id, doc.data());
        } catch (_) {
          continue;
        }
      }
    }

    if (snapshot.docs.isEmpty) {
      throw Exception('No passages available for ${type.name}.');
    }

    // Pick the first valid document
    for (final doc in snapshot.docs) {
      try {
        return _fromFirestore(doc.id, doc.data());
      } catch (_) {
        continue;
      }
    }
    throw Exception('Could not parse any passage for ${type.name}.');
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  QuestionType? _readQuestionType(Map<String, dynamic> data) {
    final topLevelRaw = _firstNonEmptyString([
      data['questionType'],
      data['type'],
    ]);
    if (topLevelRaw != null) return parseQuestionType(topLevelRaw);

    final rawQuestions = data['questions'];
    if (rawQuestions is List && rawQuestions.isNotEmpty) {
      final firstQuestion = rawQuestions.first;
      if (firstQuestion is Map) {
        final questionRaw = _firstNonEmptyString([firstQuestion['type']]);
        if (questionRaw != null) return parseQuestionType(questionRaw);
      }
    }

    return null;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  PracticePassage _fromFirestore(String docId, Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);

    // Ensure the id field is populated
    if ((normalized['id'] as String?)?.isEmpty ?? true) {
      normalized['id'] = normalized['passageId'] as String? ?? docId;
    }

    return PracticePassage.fromMap(normalized);
  }
}

@riverpod
PassageRepository passageRepository(Ref ref) {
  return PassageRepository(FirebaseFirestore.instance);
}
