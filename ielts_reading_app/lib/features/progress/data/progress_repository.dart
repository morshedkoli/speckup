import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/band_calculator.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../domain/progress_stats.dart';
import 'history_repository.dart';

part 'progress_repository.g.dart';

class ProgressRepository {
  final FirebaseFirestore _firestore;

  ProgressRepository(this._firestore);

  Stream<ProgressStats> watchProgressStats(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => _compute(snapshot.docs));
  }

  ProgressStats _compute(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return ProgressStats.empty;

    final dataPoints = <BandDataPoint>[];

    for (final doc in docs) {
      final data = doc.data();
      final score = (data['score'] as num?)?.toDouble() ?? 0.0;
      final questionCount = (data['questionCount'] as num?)?.toInt() ?? 3;
      final correctCount = (score * questionCount).round();
      final band = BandCalculator.calculateBandFromRaw(
        correctCount,
        totalQuestions: questionCount,
      );
      final ts = data['timestamp'];
      final date = ts != null ? (ts as Timestamp).toDate() : DateTime.now();
      dataPoints.add(BandDataPoint(date: date, band: band));
    }

    final bands = dataPoints.map((p) => p.band).toList();
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

@riverpod
ProgressRepository progressRepository(Ref ref) {
  return ProgressRepository(FirebaseFirestore.instance);
}

@riverpod
Stream<ProgressStats> progressStatsStream(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(ProgressStats.empty);
  return ref.watch(progressRepositoryProvider).watchProgressStats(user.uid);
}

