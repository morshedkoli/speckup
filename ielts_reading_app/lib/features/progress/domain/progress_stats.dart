class BandDataPoint {
  final DateTime date;
  final double band;
  const BandDataPoint({required this.date, required this.band});
}

class ProgressStats {
  final double currentBand;
  final double averageBand;
  final double bestBand;
  final int totalSessions;
  final List<BandDataPoint> bandHistory;
  
  // Gamification fields
  final int currentStreak;
  final int longestStreak;
  final int xp;
  final DateTime? lastSessionDate;

  const ProgressStats({
    required this.currentBand,
    required this.averageBand,
    required this.bestBand,
    required this.totalSessions,
    required this.bandHistory,
    required this.currentStreak,
    required this.longestStreak,
    required this.xp,
    this.lastSessionDate,
  });

  static const empty = ProgressStats(
    currentBand: 0,
    averageBand: 0,
    bestBand: 0,
    totalSessions: 0,
    bandHistory: [],
    currentStreak: 0,
    longestStreak: 0,
    xp: 0,
    lastSessionDate: null,
  );

  /// Positive = improving, negative = declining, 0 = flat/no data
  double get trend => bandHistory.length < 2
      ? 0
      : bandHistory.last.band - bandHistory[bandHistory.length - 2].band;

  String get bandLabel {
    if (currentBand >= 8.5) return 'Expert';
    if (currentBand >= 7.5) return 'Very Good';
    if (currentBand >= 6.5) return 'Competent';
    if (currentBand >= 5.5) return 'Modest';
    if (currentBand >= 4.5) return 'Limited';
    if (currentBand > 0)    return 'Basic';
    return 'Not Assessed';
  }
}
