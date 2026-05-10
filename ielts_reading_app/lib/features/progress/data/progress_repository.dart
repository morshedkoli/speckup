import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../../core/utils/band_calculator.dart';
import '../../../services/firebase/firebase_providers.dart';
import '../domain/progress_stats.dart';

class ProgressRepository {
  ProgressRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _cachePrefix = 'progress_stats_';

  Stream<ProgressStats> watchProgressStats(String uid) {
    final controller = StreamController<ProgressStats>();
    final readingDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final writingDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final vocabularyDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final synonymDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    ProgressStats? cached = _readCached(uid);
    if (cached != null) {
      scheduleMicrotask(() {
        if (!controller.isClosed) controller.add(cached);
      });
    }

    void emit() {
      final stats = _compute(
        readingDocs: readingDocs,
        writingDocs: writingDocs,
        vocabularyDocs: vocabularyDocs,
        synonymDocs: synonymDocs,
      );
      _cache(uid, stats);
      if (!controller.isClosed) controller.add(stats);
    }

    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[
      _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen(
        (snapshot) {
          readingDocs
            ..clear()
            ..addAll(snapshot.docs);
          emit();
        },
        onError: controller.addError,
      ),
      _firestore
          .collection('users')
          .doc(uid)
          .collection('writing_history')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen(
        (snapshot) {
          writingDocs
            ..clear()
            ..addAll(snapshot.docs);
          emit();
        },
        onError: controller.addError,
      ),
      _firestore
          .collection('users')
          .doc(uid)
          .collection('learned_words')
          .orderBy('learnedAt', descending: false)
          .snapshots()
          .listen(
        (snapshot) {
          vocabularyDocs
            ..clear()
            ..addAll(snapshot.docs);
          emit();
        },
        onError: controller.addError,
      ),
      _firestore
          .collection('users')
          .doc(uid)
          .collection('synonym_quizzes')
          .orderBy('completedAt', descending: false)
          .snapshots()
          .listen(
        (snapshot) {
          synonymDocs
            ..clear()
            ..addAll(snapshot.docs);
          emit();
        },
        onError: (_) {
          synonymDocs.clear();
          emit();
        },
      ),
    ];

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  ProgressStats _compute({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> readingDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> writingDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> vocabularyDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> synonymDocs,
  }) {
    final activities = <ProgressActivity>[];
    final bandHistory = <BandDataPoint>[];
    final allActivityDays = <DateTime>[];
    final weakAreaBuckets = <String, _WeakAreaBucket>{};

    var correctReadingAnswers = 0;
    var totalReadingAnswers = 0;

    for (final doc in readingDocs) {
      final data = doc.data();
      final score = (data['score'] as num?)?.toDouble() ?? 0;
      final questionCount = (data['questionCount'] as num?)?.toInt() ?? 0;
      final correct = (score * questionCount).round();
      final band = BandCalculator.calculateBandFromRaw(
        correct,
        totalQuestions: questionCount == 0 ? 1 : questionCount,
      );
      final date = _readDate(data['timestamp']) ?? DateTime.now();

      correctReadingAnswers += correct;
      totalReadingAnswers += questionCount;
      bandHistory.add(
        BandDataPoint(
          date: date,
          band: band,
          type: ProgressActivityType.reading,
        ),
      );
      activities.add(
        ProgressActivity(
          id: doc.id,
          type: ProgressActivityType.reading,
          title: data['title'] as String? ?? 'Reading practice',
          date: date,
          score: score,
          band: band,
          xp: 18 + (score * 12).round(),
        ),
      );
      allActivityDays.add(date);

      final questions = data['questions'];
      if (questions is List) {
        for (final raw in questions) {
          if (raw is! Map) continue;
          final type = raw['type'] as String? ?? 'reading';
          final bucket = weakAreaBuckets.putIfAbsent(
            _labelForQuestionType(type),
            () => _WeakAreaBucket(),
          );
          bucket.attempts += 1;
          if (raw['isCorrect'] == true) bucket.correct += 1;
        }
      }
    }

    var writingBandSum = 0.0;
    for (final doc in writingDocs) {
      final data = doc.data();
      final band = (data['overallBand'] as num?)?.toDouble() ?? 0;
      final date = _readDate(data['timestamp']) ?? DateTime.now();
      writingBandSum += band;
      if (band > 0) {
        bandHistory.add(
          BandDataPoint(
            date: date,
            band: band,
            type: ProgressActivityType.writing,
          ),
        );
      }
      activities.add(
        ProgressActivity(
          id: doc.id,
          type: ProgressActivityType.writing,
          title: data['title'] as String? ?? 'Writing task',
          date: date,
          band: band > 0 ? band : null,
          xp: 28 + (band * 4).round(),
        ),
      );
      allActivityDays.add(date);
    }

    for (final doc in vocabularyDocs) {
      final data = doc.data();
      final date = _readDate(data['learnedAt']) ?? DateTime.now();
      activities.add(
        ProgressActivity(
          id: doc.id,
          type: ProgressActivityType.vocabulary,
          title: data['word'] as String? ?? 'Vocabulary word',
          date: date,
          xp: 6,
        ),
      );
      allActivityDays.add(date);
    }

    for (final doc in synonymDocs) {
      final data = doc.data();
      final date = _readDate(data['completedAt']) ?? DateTime.now();
      final score = (data['score'] as num?)?.toDouble();
      activities.add(
        ProgressActivity(
          id: doc.id,
          type: ProgressActivityType.synonyms,
          title: 'Synonyms quiz',
          date: date,
          score: score,
          xp: 12 + ((score ?? 0) * 8).round(),
        ),
      );
      allActivityDays.add(date);
    }

    activities.sort((a, b) => b.date.compareTo(a.date));
    bandHistory.sort((a, b) => a.date.compareTo(b.date));

    final bands = bandHistory.map((point) => point.band).where((b) => b > 0);
    final averageBand =
        bands.isEmpty ? 0.0 : bands.reduce((a, b) => a + b) / bands.length;
    final bestBand =
        bands.isEmpty ? 0.0 : bands.reduce((a, b) => a > b ? a : b);
    final currentBand = bandHistory.isEmpty ? 0.0 : bandHistory.last.band;
    final writingAverageBand =
        writingDocs.isEmpty ? 0.0 : writingBandSum / writingDocs.length;
    final readingAccuracy = totalReadingAnswers == 0
        ? 0.0
        : correctReadingAnswers / totalReadingAnswers;

    final xp =
        activities.fold<int>(0, (total, activity) => total + activity.xp);
    final levelInfo = _levelForXp(xp);
    final streak = _computeStreaks(allActivityDays);
    final today = _dateOnly(DateTime.now());
    final dailyGoalCompleted = activities
        .where((activity) => _dateOnly(activity.date) == today)
        .fold<int>(0, (total, activity) => total + activity.xp);
    final weakAreas = weakAreaBuckets.entries
        .map(
          (entry) => WeakArea(
            label: entry.key,
            accuracy: entry.value.accuracy,
            attempts: entry.value.attempts,
          ),
        )
        .where((area) => area.attempts >= 2)
        .toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return ProgressStats(
      currentBand: _oneDecimal(currentBand),
      averageBand: _oneDecimal(averageBand),
      bestBand: _oneDecimal(bestBand),
      totalSessions: readingDocs.length + writingDocs.length,
      readingSessions: readingDocs.length,
      writingSessions: writingDocs.length,
      vocabularyLearned: vocabularyDocs.length,
      synonymQuizzes: synonymDocs.length,
      readingAccuracy: readingAccuracy,
      writingAverageBand: _oneDecimal(writingAverageBand),
      bandHistory: bandHistory,
      currentStreak: streak.current,
      longestStreak: streak.longest,
      xp: xp,
      level: levelInfo.level,
      xpForCurrentLevel: levelInfo.currentFloor,
      xpForNextLevel: levelInfo.nextFloor,
      dailyGoalTarget: 30,
      dailyGoalCompleted: dailyGoalCompleted.clamp(0, 30),
      weakAreas: weakAreas.take(4).toList(),
      badges: _badges(
        totalSessions: readingDocs.length + writingDocs.length,
        streak: streak.longest,
        vocabularyLearned: vocabularyDocs.length,
        bestBand: bestBand,
      ),
      recentActivities: activities.take(12).toList(),
      lastSessionDate: allActivityDays.isEmpty
          ? null
          : allActivityDays.reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  Future<void> _cache(String uid, ProgressStats stats) async {
    await HiveBoxes.progress
        .put('$_cachePrefix$uid', jsonEncode(_toCache(stats)));
  }

  ProgressStats? _readCached(String uid) {
    final raw = HiveBoxes.progress.get('$_cachePrefix$uid');
    if (raw is! String) return null;
    try {
      return _fromCache(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toCache(ProgressStats stats) {
    return {
      'currentBand': stats.currentBand,
      'averageBand': stats.averageBand,
      'bestBand': stats.bestBand,
      'totalSessions': stats.totalSessions,
      'readingSessions': stats.readingSessions,
      'writingSessions': stats.writingSessions,
      'vocabularyLearned': stats.vocabularyLearned,
      'synonymQuizzes': stats.synonymQuizzes,
      'readingAccuracy': stats.readingAccuracy,
      'writingAverageBand': stats.writingAverageBand,
      'currentStreak': stats.currentStreak,
      'longestStreak': stats.longestStreak,
      'xp': stats.xp,
      'level': stats.level,
      'xpForCurrentLevel': stats.xpForCurrentLevel,
      'xpForNextLevel': stats.xpForNextLevel,
      'dailyGoalCompleted': stats.dailyGoalCompleted,
      'lastSessionDate': stats.lastSessionDate?.toIso8601String(),
    };
  }

  ProgressStats _fromCache(Map<String, dynamic> map) {
    return ProgressStats(
      currentBand: (map['currentBand'] as num?)?.toDouble() ?? 0,
      averageBand: (map['averageBand'] as num?)?.toDouble() ?? 0,
      bestBand: (map['bestBand'] as num?)?.toDouble() ?? 0,
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
      readingSessions: (map['readingSessions'] as num?)?.toInt() ?? 0,
      writingSessions: (map['writingSessions'] as num?)?.toInt() ?? 0,
      vocabularyLearned: (map['vocabularyLearned'] as num?)?.toInt() ?? 0,
      synonymQuizzes: (map['synonymQuizzes'] as num?)?.toInt() ?? 0,
      readingAccuracy: (map['readingAccuracy'] as num?)?.toDouble() ?? 0,
      writingAverageBand: (map['writingAverageBand'] as num?)?.toDouble() ?? 0,
      bandHistory: const [],
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      xpForCurrentLevel: (map['xpForCurrentLevel'] as num?)?.toInt() ?? 0,
      xpForNextLevel: (map['xpForNextLevel'] as num?)?.toInt() ?? 120,
      dailyGoalTarget: 30,
      dailyGoalCompleted: (map['dailyGoalCompleted'] as num?)?.toInt() ?? 0,
      weakAreas: const [],
      badges: const [],
      recentActivities: const [],
      lastSessionDate:
          DateTime.tryParse(map['lastSessionDate'] as String? ?? ''),
    );
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  _StreakResult _computeStreaks(List<DateTime> dates) {
    if (dates.isEmpty) return const _StreakResult(current: 0, longest: 0);
    final days = dates.map(_dateOnly).toSet().toList()..sort();

    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        run += 1;
        if (run > longest) longest = run;
      } else if (diff > 1) {
        run = 1;
      }
    }

    final today = _dateOnly(DateTime.now());
    final lastDay = days.last;
    final current = today.difference(lastDay).inDays <= 1 ? run : 0;
    return _StreakResult(current: current, longest: longest);
  }

  _LevelInfo _levelForXp(int xp) {
    var level = 1;
    var currentFloor = 0;
    var nextFloor = 120;

    while (xp >= nextFloor) {
      level += 1;
      currentFloor = nextFloor;
      nextFloor += 120 + (level - 1) * 30;
    }

    return _LevelInfo(
      level: level,
      currentFloor: currentFloor,
      nextFloor: nextFloor,
    );
  }

  List<AchievementBadge> _badges({
    required int totalSessions,
    required int streak,
    required int vocabularyLearned,
    required double bestBand,
  }) {
    return [
      AchievementBadge(
        id: 'first-session',
        title: 'First Step',
        description: 'Complete your first session',
        unlocked: totalSessions >= 1,
      ),
      AchievementBadge(
        id: 'streak-3',
        title: 'On Fire',
        description: 'Reach a 3-day streak',
        unlocked: streak >= 3,
      ),
      AchievementBadge(
        id: 'vocab-25',
        title: 'Word Builder',
        description: 'Learn 25 vocabulary words',
        unlocked: vocabularyLearned >= 25,
      ),
      AchievementBadge(
        id: 'band-7',
        title: 'Band 7 Ready',
        description: 'Score band 7 or higher',
        unlocked: bestBand >= 7,
      ),
    ];
  }

  String _labelForQuestionType(String type) {
    final spaced = type.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    return spaced
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  double _oneDecimal(double value) => double.parse(value.toStringAsFixed(1));
}

class _WeakAreaBucket {
  var attempts = 0;
  var correct = 0;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

class _StreakResult {
  const _StreakResult({required this.current, required this.longest});

  final int current;
  final int longest;
}

class _LevelInfo {
  const _LevelInfo({
    required this.level,
    required this.currentFloor,
    required this.nextFloor,
  });

  final int level;
  final int currentFloor;
  final int nextFloor;
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(FirebaseFirestore.instance);
});

final progressStatsStreamProvider = StreamProvider<ProgressStats>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(ProgressStats.empty);
  return ref.watch(progressRepositoryProvider).watchProgressStats(user.uid);
});
