import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/models.dart';

class PracticeAssignmentRepository {
  PracticeAssignmentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<PracticeSessionState?> getAssignedSession({
    required String userKey,
    required QuestionType type,
    String? uid,
  }) async {
    final localSession = _findAssignedSession(
      sessions: _readLocalSessions(userKey),
      type: type,
    );
    if (localSession != null) {
      return localSession;
    }

    if (uid == null) return null;

    final remoteSession = await _readRemoteAssignedSession(uid, type);
    if (remoteSession != null) {
      await _upsertLocalSession(userKey, remoteSession);
    }

    return remoteSession;
  }

  Future<Set<QuestionType>> getAssignedTypes({
    required String userKey,
    String? uid,
  }) async {
    final assignedTypes = _readLocalSessions(userKey)
        .where((session) => session.status == PracticeSessionStatus.assigned)
        .map((session) => session.questionType)
        .whereType<QuestionType>()
        .toSet();

    if (uid == null) return assignedTypes;

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('practice_passages')
        .where('status', isEqualTo: PracticeSessionStatus.assigned.name)
        .get();

    for (final doc in snapshot.docs) {
      final session = _sessionFromRemote(doc.data());
      if (session.questionType != null) {
        assignedTypes.add(session.questionType!);
        await _upsertLocalSession(userKey, session);
      }
    }

    return assignedTypes;
  }

  Future<void> assignSession({
    required String userKey,
    required PracticeSessionState session,
    String? uid,
  }) async {
    if (session.passage == null || session.questionType == null) return;

    await _upsertLocalSession(userKey, session);

    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('practice_passages')
        .doc(session.passage!.id)
        .set(_sessionToRemote(session,
            assignedAt: FieldValue.serverTimestamp()));
  }

  Future<void> saveLocalProgress({
    required String userKey,
    required PracticeSessionState session,
  }) async {
    if (session.passage == null) return;
    await _upsertLocalSession(userKey, session);
  }

  Future<void> markCompleted({
    required String userKey,
    required PracticeSessionState session,
    String? uid,
  }) async {
    if (session.passage == null || session.questionType == null) return;

    await _upsertLocalSession(userKey, session);

    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('practice_passages')
        .doc(session.passage!.id)
        .set(
          _sessionToRemote(
            session,
            completedAt: FieldValue.serverTimestamp(),
          ),
          SetOptions(merge: true),
        );
  }

  PracticeSessionState? _findAssignedSession({
    required List<PracticeSessionState> sessions,
    required QuestionType type,
  }) {
    final assigned = sessions
        .where(
          (session) =>
              session.questionType == type &&
              session.status == PracticeSessionStatus.assigned &&
              session.passage != null,
        )
        .toList();

    if (assigned.isEmpty) return null;

    assigned.sort((a, b) {
      final aTime = a.assignedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.assignedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return assigned.first;
  }

  List<PracticeSessionState> _readLocalSessions(String userKey) {
    final raw = HiveBoxes.session.get(_localStorageKey(userKey));
    if (raw is! List) return const [];

    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => PracticeSessionState.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> _upsertLocalSession(
    String userKey,
    PracticeSessionState session,
  ) async {
    final sessions = _readLocalSessions(userKey);
    final passageId = session.passage?.id;
    if (passageId == null) return;

    final updated = <PracticeSessionState>[
      for (final item in sessions)
        if (item.passage?.id != passageId) item,
      session,
    ];

    await HiveBoxes.session.put(
      _localStorageKey(userKey),
      updated.map((item) => item.toMap()).toList(),
    );
  }

  Future<PracticeSessionState?> _readRemoteAssignedSession(
    String uid,
    QuestionType type,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('practice_passages')
        .where('questionType', isEqualTo: type.name)
        .where('status', isEqualTo: PracticeSessionStatus.assigned.name)
        .limit(10)
        .get();

    final sessions = snapshot.docs
        .map((doc) => _sessionFromRemote(doc.data()))
        .where((session) => session.passage != null)
        .toList();

    if (sessions.isEmpty) return null;

    sessions.sort((a, b) {
      final aTime = a.assignedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.assignedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return sessions.first;
  }

  PracticeSessionState _sessionFromRemote(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    normalized['assignedAt'] = _timestampToIsoString(data['assignedAt']);
    normalized['completedAt'] = _timestampToIsoString(data['completedAt']);
    return PracticeSessionState.fromMap(normalized);
  }

  Map<String, dynamic> _sessionToRemote(
    PracticeSessionState session, {
    Object? assignedAt,
    Object? completedAt,
  }) {
    return {
      'passage': session.passage?.toMap(),
      'passageId': session.passage?.id,
      'questionType': session.questionType?.name,
      'userAnswers': session.userAnswers,
      'isSubmitted': session.isSubmitted,
      'score': session.score,
      'status': session.status.name,
      'assignedAt': assignedAt ?? session.assignedAt?.toIso8601String(),
      'completedAt': completedAt ?? session.completedAt?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _localStorageKey(String userKey) {
    return 'reading.practice_assignments.$userKey';
  }

  String? _timestampToIsoString(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is String) {
      return value;
    }
    return null;
  }
}

final practiceAssignmentRepositoryProvider =
    Provider<PracticeAssignmentRepository>((ref) {
  return PracticeAssignmentRepository(FirebaseFirestore.instance);
});
