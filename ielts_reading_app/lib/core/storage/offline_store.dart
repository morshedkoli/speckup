import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';

class OfflineRecord {
  const OfflineRecord({
    required this.key,
    required this.data,
    required this.updatedAt,
  });

  final String key;
  final Map<String, dynamic> data;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'data': data,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OfflineRecord.fromMap(Map<String, dynamic> map) {
    return OfflineRecord(
      key: map['key'] as String? ?? '',
      data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class OfflineStore {
  OfflineStore(this._box);

  final Box<dynamic> _box;

  Future<void> put(
    String collection,
    String id,
    Map<String, dynamic> data, {
    DateTime? updatedAt,
  }) async {
    final record = OfflineRecord(
      key: _key(collection, id),
      data: data,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    await _box.put(record.key, jsonEncode(record.toMap()));
  }

  OfflineRecord? get(String collection, String id) {
    final raw = _box.get(_key(collection, id));
    if (raw is! String) return null;
    try {
      return OfflineRecord.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  List<OfflineRecord> list(String collection) {
    final prefix = '$collection/';
    return _box.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix))
        .map((key) => _box.get(key))
        .whereType<String>()
        .map((raw) {
          try {
            return OfflineRecord.fromMap(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<OfflineRecord>()
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> delete(String collection, String id) {
    return _box.delete(_key(collection, id));
  }

  String _key(String collection, String id) => '$collection/$id';
}

final offlineStoreProvider = Provider<OfflineStore>((ref) {
  return OfflineStore(HiveBoxes.offline);
});
