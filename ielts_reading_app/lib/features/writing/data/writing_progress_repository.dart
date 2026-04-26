import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firebase_providers.dart';
import '../../progress/domain/progress_stats.dart';

class WritingProgressRepository {
  WritingProgressRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<ProgressStats> watchProgressStats(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('writing_history')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => _compute(snapshot.docs));
  }

  ProgressStats _compute(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return ProgressStats.empty;

    final dataPoints = <BandDataPoint>[];
    for (final doc in docs) {
      final data = doc.data();
      final band = (data['overallBand'] as num?)?.toDouble() ?? 0.0;
      final ts = data['timestamp'];
      final date = ts != null ? (ts as Timestamp).toDate() : DateTime.now();
      dataPoints.add(BandDataPoint(date: date, band: band));
    }

    final bands = dataPoints.map((point) => point.band).toList();
    final averageBand = bands.reduce((a, b) => a + b) / bands.length;
    final bestBand = bands.reduce((a, b) => a > b ? a : b);

    return ProgressStats(
      currentBand: dataPoints.last.band,
      averageBand: double.parse(averageBand.toStringAsFixed(1)),
      bestBand: bestBand,
      totalSessions: dataPoints.length,
      bandHistory: dataPoints,
    );
  }
}

final writingProgressRepositoryProvider =
    Provider<WritingProgressRepository>((ref) {
  return WritingProgressRepository(FirebaseFirestore.instance);
});

final writingProgressStatsStreamProvider = StreamProvider<ProgressStats>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(ProgressStats.empty);

  return ref
      .watch(writingProgressRepositoryProvider)
      .watchProgressStats(user.uid);
});
