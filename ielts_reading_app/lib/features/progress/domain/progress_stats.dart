enum ProgressActivityType { reading, writing, vocabulary, synonyms }

class BandDataPoint {
  const BandDataPoint({
    required this.date,
    required this.band,
    required this.type,
  });

  final DateTime date;
  final double band;
  final ProgressActivityType type;
}

class WeakArea {
  const WeakArea({
    required this.label,
    required this.accuracy,
    required this.attempts,
  });

  final String label;
  final double accuracy;
  final int attempts;
}

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
}

class ProgressActivity {
  const ProgressActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.xp,
    this.score,
    this.band,
  });

  final String id;
  final ProgressActivityType type;
  final String title;
  final DateTime date;
  final int xp;
  final double? score;
  final double? band;
}

class ProgressStats {
  const ProgressStats({
    required this.currentBand,
    required this.averageBand,
    required this.bestBand,
    required this.totalSessions,
    required this.readingSessions,
    required this.writingSessions,
    required this.vocabularyLearned,
    required this.synonymQuizzes,
    required this.readingAccuracy,
    required this.writingAverageBand,
    required this.bandHistory,
    required this.currentStreak,
    required this.longestStreak,
    required this.xp,
    required this.level,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.dailyGoalTarget,
    required this.dailyGoalCompleted,
    required this.weakAreas,
    required this.badges,
    required this.recentActivities,
    this.lastSessionDate,
  });

  final double currentBand;
  final double averageBand;
  final double bestBand;
  final int totalSessions;
  final int readingSessions;
  final int writingSessions;
  final int vocabularyLearned;
  final int synonymQuizzes;
  final double readingAccuracy;
  final double writingAverageBand;
  final List<BandDataPoint> bandHistory;
  final int currentStreak;
  final int longestStreak;
  final int xp;
  final int level;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final int dailyGoalTarget;
  final int dailyGoalCompleted;
  final List<WeakArea> weakAreas;
  final List<AchievementBadge> badges;
  final List<ProgressActivity> recentActivities;
  final DateTime? lastSessionDate;

  static const empty = ProgressStats(
    currentBand: 0,
    averageBand: 0,
    bestBand: 0,
    totalSessions: 0,
    readingSessions: 0,
    writingSessions: 0,
    vocabularyLearned: 0,
    synonymQuizzes: 0,
    readingAccuracy: 0,
    writingAverageBand: 0,
    bandHistory: [],
    currentStreak: 0,
    longestStreak: 0,
    xp: 0,
    level: 1,
    xpForCurrentLevel: 0,
    xpForNextLevel: 120,
    dailyGoalTarget: 30,
    dailyGoalCompleted: 0,
    weakAreas: [],
    badges: [],
    recentActivities: [],
  );

  bool get hasActivity =>
      readingSessions > 0 || writingSessions > 0 || vocabularyLearned > 0;

  double get trend => bandHistory.length < 2
      ? 0
      : bandHistory.last.band - bandHistory[bandHistory.length - 2].band;

  double get levelProgress {
    final span = xpForNextLevel - xpForCurrentLevel;
    if (span <= 0) return 1;
    return ((xp - xpForCurrentLevel) / span).clamp(0, 1);
  }

  double get dailyGoalProgress =>
      (dailyGoalCompleted / dailyGoalTarget).clamp(0, 1);

  String get bandLabel {
    if (currentBand >= 8.5) return 'Expert';
    if (currentBand >= 7.5) return 'Very Good';
    if (currentBand >= 6.5) return 'Competent';
    if (currentBand >= 5.5) return 'Modest';
    if (currentBand >= 4.5) return 'Limited';
    if (currentBand > 0) return 'Basic';
    return 'Not Assessed';
  }
}
