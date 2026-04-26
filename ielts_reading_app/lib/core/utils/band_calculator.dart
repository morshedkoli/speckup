class BandCalculator {
  BandCalculator._();

  /// Approximate IELTS Reading Score (Academic)
  /// Map raw score (out of 40) to band score.
  static double calculateBandFromRaw(int rawScore, {int totalQuestions = 40}) {
    // If not exactly 40, map proportionally to 40 first.
    final double adjustedScore = (rawScore / totalQuestions) * 40;
    final int roundedScore = adjustedScore.round();

    if (roundedScore >= 39) return 9.0;
    if (roundedScore >= 37) return 8.5;
    if (roundedScore >= 35) return 8.0;
    if (roundedScore >= 33) return 7.5;
    if (roundedScore >= 30) return 7.0;
    if (roundedScore >= 27) return 6.5;
    if (roundedScore >= 23) return 6.0;
    if (roundedScore >= 19) return 5.5;
    if (roundedScore >= 15) return 5.0;
    if (roundedScore >= 13) return 4.5;
    if (roundedScore >= 10) return 4.0;
    if (roundedScore >= 8) return 3.5;
    if (roundedScore >= 6) return 3.0;
    if (roundedScore >= 4) return 2.5;
    return 0.0;
  }
}
