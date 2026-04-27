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

    // Gamification Calculations
    int currentStreak = 0;
    int longestStreak = 0;
    int xp = dataPoints.length * 10; // 10 XP per session

    if (dataPoints.isNotEmpty) {
      // Sort points by date just in case
      dataPoints.sort((a, b) => a.date.compareTo(b.date));
      
      int tempStreak = 1;
      longestStreak = 1;
      
      for (int i = 1; i < dataPoints.length; i++) {
        final prevDate = dataPoints[i - 1].date;
        final currDate = dataPoints[i].date;
        
        final prevDay = DateTime(prevDate.year, prevDate.month, prevDate.day);
        final currDay = DateTime(currDate.year, currDate.month, currDate.day);
        
        final diff = currDay.difference(prevDay).inDays;
        
        if (diff == 0) {
          // Same day, streak doesn't change
        } else if (diff == 1) {
          // Next day, increment streak
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else {
          // Broken streak
          tempStreak = 1;
        }
      }

      // Check if current streak is still active today
      final lastDate = dataPoints.last.date;
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final daysSinceLastSession = today.difference(lastDay).inDays;

      if (daysSinceLastSession == 0 || daysSinceLastSession == 1) {
        currentStreak = tempStreak;
      } else {
        currentStreak = 0;
      }
    }

    return ProgressStats(
      currentBand: dataPoints.last.band,
      averageBand: double.parse(averageBand.toStringAsFixed(1)),
      bestBand: bestBand,
      totalSessions: dataPoints.length,
      bandHistory: dataPoints,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      xp: xp,
      lastSessionDate: dataPoints.isNotEmpty ? dataPoints.last.date : null,
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

