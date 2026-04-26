import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/models.dart';

class WritingAssignmentRepository {
  WritingAssignmentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<WritingSessionState?> getAssignedSession({
    required String userKey,
    required WritingTaskType type,
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

  Future<Set<WritingTaskType>> getAssignedTypes({
    required String userKey,
    String? uid,
  }) async {
    final assignedTypes = _readLocalSessions(userKey)
        .where((session) => session.status == WritingSessionStatus.assigned)
        .map((session) => session.taskType)
        .whereType<WritingTaskType>()
        .toSet();

    if (uid == null) return assignedTypes;

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('writing_tasks')
        .where('status', isEqualTo: WritingSessionStatus.assigned.name)
        .get();

    for (final doc in snapshot.docs) {
      final session = _sessionFromRemote(doc.data());
      if (session.taskType != null) {
        assignedTypes.add(session.taskType!);
        await _upsertLocalSession(userKey, session);
      }
    }

    return assignedTypes;
  }

  Future<void> assignSession({
    required String userKey,
    required WritingSessionState session,
    String? uid,
  }) async {
    if (session.task == null || session.taskType == null) return;

    await _upsertLocalSession(userKey, session);

    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('writing_tasks')
        .doc(session.task!.id)
        .set(
          _sessionToRemote(
            session,
            assignedAt: FieldValue.serverTimestamp(),
          ),
        );
  }

  Future<void> saveLocalProgress({
    required String userKey,
    required WritingSessionState session,
  }) async {
    if (session.task == null) return;
    await _upsertLocalSession(userKey, session);
  }

  Future<void> markCompleted({
    required String userKey,
    required WritingSessionState session,
    String? uid,
  }) async {
    if (session.task == null || session.taskType == null) return;

    await _upsertLocalSession(userKey, session);

    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('writing_tasks')
        .doc(session.task!.id)
        .set(
          _sessionToRemote(
            session,
            completedAt: FieldValue.serverTimestamp(),
          ),
          SetOptions(merge: true),
        );
  }

  List<WritingSessionState> _readLocalSessions(String userKey) {
    final raw = HiveBoxes.session.get(_localStorageKey(userKey));
    if (raw is! List) return const [];

    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => WritingSessionState.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> _upsertLocalSession(
    String userKey,
    WritingSessionState session,
  ) async {
    final sessions = _readLocalSessions(userKey);
    final taskId = session.task?.id;
    if (taskId == null) return;

    final updated = <WritingSessionState>[
      for (final item in sessions)
        if (item.task?.id != taskId) item,
      session,
    ];

    await HiveBoxes.session.put(
      _localStorageKey(userKey),
      updated.map((item) => item.toMap()).toList(),
    );
  }

  WritingSessionState? _findAssignedSession({
    required List<WritingSessionState> sessions,
    required WritingTaskType type,
  }) {
    final assigned = sessions
        .where(
          (session) =>
              session.taskType == type &&
              session.status == WritingSessionStatus.assigned &&
              session.task != null,
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

  Future<WritingSessionState?> _readRemoteAssignedSession(
    String uid,
    WritingTaskType type,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('writing_tasks')
        .where('taskType', isEqualTo: type.name)
        .where('status', isEqualTo: WritingSessionStatus.assigned.name)
        .limit(10)
        .get();

    final sessions = snapshot.docs
        .map((doc) => _sessionFromRemote(doc.data()))
        .where((session) => session.task != null)
        .toList();

    if (sessions.isEmpty) return null;

    sessions.sort((a, b) {
      final aTime = a.assignedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.assignedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return sessions.first;
  }

  WritingSessionState _sessionFromRemote(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    normalized['assignedAt'] = _timestampToIsoString(data['assignedAt']);
    normalized['completedAt'] = _timestampToIsoString(data['completedAt']);
    return WritingSessionState.fromMap(normalized);
  }

  Map<String, dynamic> _sessionToRemote(
    WritingSessionState session, {
    Object? assignedAt,
    Object? completedAt,
  }) {
    return {
      'task': session.task?.toMap(),
      'taskId': session.task?.id,
      'taskType': session.taskType?.name,
      'userResponse': session.userResponse,
      'isSubmitted': session.isSubmitted,
      'status': session.status.name,
      'assignedAt': assignedAt ?? session.assignedAt?.toIso8601String(),
      'completedAt': completedAt ?? session.completedAt?.toIso8601String(),
      'evaluation': session.evaluation?.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _localStorageKey(String userKey) {
    return 'writing.assignments.$userKey';
  }

  String? _timestampToIsoString(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is String) return value;
    return null;
  }
}

final writingAssignmentRepositoryProvider =
    Provider<WritingAssignmentRepository>((ref) {
  return WritingAssignmentRepository(FirebaseFirestore.instance);
});
