import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../network/connectivity_service.dart';
import '../storage/hive_boxes.dart';

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.path,
    required this.data,
    required this.updatedAt,
  });

  final String id;
  final String path;
  final Map<String, dynamic> data;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'data': data,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as String? ?? '',
      path: map['path'] as String? ?? '',
      data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SyncQueue {
  SyncQueue(this._box);

  final Box<dynamic> _box;

  Future<void> enqueue({
    required String path,
    required Map<String, dynamic> data,
    DateTime? updatedAt,
  }) async {
    final now = updatedAt ?? DateTime.now();
    final operation = SyncOperation(
      id: path,
      path: path,
      data: {
        ...data,
        'updatedAt': now.toIso8601String(),
      },
      updatedAt: now,
    );
    await _box.put(operation.id, jsonEncode(operation.toMap()));
  }

  List<SyncOperation> pending() {
    return _box.values
        .whereType<String>()
        .map((raw) {
          try {
            return SyncOperation.fromMap(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<SyncOperation>()
        .toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
  }

  Future<void> remove(String id) => _box.delete(id);
}

class SyncManager {
  SyncManager({
    required SyncQueue queue,
    required ConnectivityService connectivity,
    required FirebaseFirestore firestore,
  })  : _queue = queue,
        _connectivity = connectivity,
        _firestore = firestore;

  final SyncQueue _queue;
  final ConnectivityService _connectivity;
  final FirebaseFirestore _firestore;

  Future<void> enqueueWrite({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    await _queue.enqueue(path: path, data: data);
    if (await _connectivity.isConnected) {
      await syncPending();
    }
  }

  Future<void> syncPending() async {
    if (!await _connectivity.isConnected) return;

    final operations = _queue.pending();
    for (var i = 0; i < operations.length; i += 450) {
      final batch = _firestore.batch();
      final chunk = operations.skip(i).take(450).toList();

      for (final operation in chunk) {
        final ref = _firestore.doc(operation.path);
        batch.set(ref, operation.data, SetOptions(merge: true));
      }

      await batch.commit();
      for (final operation in chunk) {
        await _queue.remove(operation.id);
      }
    }
  }
}

final syncQueueProvider = Provider<SyncQueue>((ref) {
  return SyncQueue(HiveBoxes.syncQueue);
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(
    queue: ref.watch(syncQueueProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    firestore: FirebaseFirestore.instance,
  );
});
