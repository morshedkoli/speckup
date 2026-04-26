import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models.dart';

part 'shared_passage_repository.g.dart';

class SharedPassageRepository {
  final FirebaseFirestore _firestore;

  SharedPassageRepository(this._firestore);

  // ─── Write helpers (used by admin / app on completion) ──────────────────────

  Future<void> savePassage(PracticePassage passage, QuestionType type) async {
    await _firestore
        .collection('shared_passages')
        .doc(passage.id)
        .set(_toFirestore(passage, type), SetOptions(merge: false));
  }

  /// Mark that this user has seen/used this passage so it won't be served again.
  Future<void> markSeen(String uid, String passageId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('seen_passages')
        .doc(passageId)
        .set({'seenAt': FieldValue.serverTimestamp()});
  }

  /// Stamp `lastUsedAt` on the shared passage so the admin can track utilisation.
  Future<void> markPassageUsed(String passageId) async {
    try {
      await _firestore
          .collection('shared_passages')
          .doc(passageId)
          .update({'lastUsedAt': FieldValue.serverTimestamp()});
    } catch (_) {
      // Non-critical — don't surface to the user
    }
  }

  // ─── Read helpers ────────────────────────────────────────────────────────────

  Future<Set<String>> _getSeenIds(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('seen_passages')
        .get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  /// Returns the first unseen passage for [type], or null if the pool is empty.
  Future<PracticePassage?> getUnseenPassage(
    String uid,
    QuestionType type,
  ) async {
    final seenIds = await _getSeenIds(uid);
    // Use the simple (no orderBy) query to avoid requiring a composite index.
    final docs = await _queryTypePassagesSimple(type, limit: 100);

    for (final doc in docs) {
      if (!seenIds.contains(doc.id)) {
        try {
          return _fromFirestore(doc.id, doc.data());
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  /// Returns how many unseen passages this user has for each [QuestionType].
  /// Only types with ≥1 unseen passage are included in the result.
  Future<Map<QuestionType, int>> getAvailableCountsPerType(String uid) async {
    final seenIds = await _getSeenIds(uid);
    final counts = <QuestionType, int>{};

    for (final type in QuestionType.values) {
      // Use simple query (no orderBy) — no composite index required.
      final docs = await _queryTypePassagesSimple(type, limit: 250);
      final unseen = docs.where((d) => !seenIds.contains(d.id)).length;
      if (unseen > 0) counts[type] = unseen;
    }
    return counts;
  }

  /// Returns unseen count for a single type (cheaper than loading all types).
  Future<int> getUnseenPassageCount(
    String uid,
    QuestionType type, {
    int fetchLimit = 250,
  }) async {
    final seenIds = await _getSeenIds(uid);
    final docs = await _queryTypePassagesSimple(type, limit: fetchLimit);
    return docs.where((doc) => !seenIds.contains(doc.id)).length;
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Map<String, dynamic> _toFirestore(
    PracticePassage passage,
    QuestionType type,
  ) {
    return {
      ...passage.toMap(),
      'questionType': type.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Parse a Firestore document into a [PracticePassage].
  ///
  /// The admin dashboard stores the type as `questionType`; the passage model
  /// uses the document id as the passage id when the map doesn't contain one.
  PracticePassage _fromFirestore(String docId, Map<String, dynamic> data) {
    // Admin field is 'questionType', not embedded in the passage itself.
    // We just need the passage data; the type is used for querying only.
    final normalized = Map<String, dynamic>.from(data);

    // Ensure 'id' falls back to the document id via passageId field
    if ((normalized['id'] as String?)?.isEmpty ?? true) {
      normalized['id'] = normalized['passageId'] as String? ?? docId;
    }

    return PracticePassage.fromMap(normalized);
  }

  /// Simple query — only filters by `questionType`.
  /// Does NOT use `orderBy`, so no composite index is required.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _queryTypePassagesSimple(
    QuestionType type, {
    required int limit,
  }) async {
    final questionTypeSnapshot = await _firestore
        .collection('shared_passages')
        .where('questionType', isEqualTo: type.name)
        .limit(limit)
        .get();
    if (questionTypeSnapshot.docs.isNotEmpty) {
      return questionTypeSnapshot.docs;
    }

    final legacyTypeSnapshot = await _firestore
        .collection('shared_passages')
        .where('type', isEqualTo: type.name)
        .limit(limit)
        .get();
    if (legacyTypeSnapshot.docs.isNotEmpty) {
      return legacyTypeSnapshot.docs;
    }

    final allDocs =
        await _firestore.collection('shared_passages').limit(limit).get();
    return allDocs.docs
        .where((doc) => _readQuestionType(doc.data()) == type)
        .toList();
  }

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
}

@riverpod
SharedPassageRepository sharedPassageRepository(Ref ref) {
  return SharedPassageRepository(FirebaseFirestore.instance);
}
