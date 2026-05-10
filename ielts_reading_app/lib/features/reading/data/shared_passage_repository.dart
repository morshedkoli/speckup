import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/cache_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../core/storage/offline_store.dart';
import '../domain/models.dart';

part 'shared_passage_repository.g.dart';

/// TTL for the per-user availability count cache (Hive).
/// After 24 h the next call re-fetches from Firestore.
const _countsCacheTtl = Duration(hours: 24);

class SharedPassageRepository {
  final FirebaseFirestore _firestore;
  final CacheService _cache;

  SharedPassageRepository(this._firestore, this._cache);

  // ─── Write helpers ──────────────────────────────────────────────────────────

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

    // Invalidate cached counts so next open re-fetches fresh data
    await _cache.delete(_countsKey(uid));
  }

  /// Stamp `lastUsedAt` on the shared passage for admin utilisation tracking.
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

  // ─── Availability counts (Hive-cached) ─────────────────────────────────────

  /// Returns how many unseen passages this user has for each [QuestionType].
  ///
  /// **Strategy**: serve from Hive cache instantly (if < 24 h old), otherwise
  /// fetch from Firestore and write-through to Hive.
  Future<Map<QuestionType, int>> getAvailableCountsPerType(String uid) async {
    // ── 1. Serve from Hive if fresh ───────────────────────────────────────────
    final cached = _cache.get<Map<String, dynamic>>(_countsKey(uid));
    if (cached != null) {
      return cached.map(
        (k, v) => MapEntry(parseQuestionType(k), (v as num).toInt()),
      );
    }

    // ── 2. Fetch from Firestore (Source.serverAndCache respects offline mode) ─
    final seenIds = await _getSeenIds(uid);
    final counts = <QuestionType, int>{};

    for (final type in QuestionType.values) {
      final docs = await _queryTypePassagesSimple(type, limit: 250);
      final unseen = docs.where((d) => !seenIds.contains(d.id)).length;
      if (unseen > 0) counts[type] = unseen;
    }

    // ── 3. Write-through to Hive ───────────────────────────────────────────────
    await _cache.set(
      _countsKey(uid),
      counts.map((k, v) => MapEntry(k.name, v)),
      ttl: _countsCacheTtl,
    );

    return counts;
  }

  // ─── Unseen passage fetch ───────────────────────────────────────────────────

  /// Returns the first unseen passage for [type], or null if the pool is empty.
  Future<PracticePassage?> getUnseenPassage(
    String uid,
    QuestionType type,
  ) async {
    final seenIds = await _getSeenIds(uid);
    final docs = await _queryTypePassagesSimple(type, limit: 100);

    if (docs.isEmpty) {
      final cached = OfflineStore(HiveBoxes.offline)
          .list('reading_passages')
          .where((record) => record.data['questionType'] == type.name);
      for (final record in cached) {
        final id = record.data['id'] as String? ?? record.key.split('/').last;
        if (seenIds.contains(id)) continue;
        return PracticePassage.fromMap(record.data);
      }
    }

    for (final doc in docs) {
      if (!seenIds.contains(doc.id)) {
        try {
          final passage = _fromFirestore(doc.id, doc.data());
          await OfflineStore(HiveBoxes.offline).put(
            'reading_passages',
            passage.id,
            {
              ...passage.toMap(),
              'questionType': type.name,
            },
          );
          return passage;
        } catch (_) {
          continue;
        }
      }
    }
    return null;
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

  // ─── Private helpers ────────────────────────────────────────────────────────

  String _countsKey(String uid) => 'passage_counts_$uid';

  Future<Set<String>> _getSeenIds(String uid) async {
    // Use Source.cache first to avoid a cold read every time
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('seen_passages')
          .get(const GetOptions(source: Source.cache));
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => d.id).toSet();
      }
    } catch (_) {
      // Cache miss — fall through to network
    }

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('seen_passages')
        .get(const GetOptions(source: Source.serverAndCache));
    return snap.docs.map((d) => d.id).toSet();
  }

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

  PracticePassage _fromFirestore(String docId, Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    if ((normalized['id'] as String?)?.isEmpty ?? true) {
      normalized['id'] = normalized['passageId'] as String? ?? docId;
    }
    return PracticePassage.fromMap(normalized);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _queryTypePassagesSimple(
    QuestionType type, {
    required int limit,
  }) async {
    // Try canonical field first (Source.serverAndCache respects offline)
    final questionTypeSnap = await _firestore
        .collection('shared_passages')
        .where('questionType', isEqualTo: type.name)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));

    if (questionTypeSnap.docs.isNotEmpty) return questionTypeSnap.docs;

    // Legacy `type` field fallback
    final legacySnap = await _firestore
        .collection('shared_passages')
        .where('type', isEqualTo: type.name)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));

    if (legacySnap.docs.isNotEmpty) return legacySnap.docs;

    // Last resort — load all and filter in-memory
    final allDocs = await _firestore
        .collection('shared_passages')
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
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
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

@riverpod
SharedPassageRepository sharedPassageRepository(Ref ref) {
  return SharedPassageRepository(
    FirebaseFirestore.instance,
    CacheService(HiveBoxes.cache),
  );
}
