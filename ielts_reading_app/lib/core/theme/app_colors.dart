import 'package:flutter/material.dart';

/// Centralised color palette matching the Stitch design system.
/// Primary: electric indigo #1337EC  |  Accent: emerald #10B981
class AppColors {
  AppColors._();

  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF1337EC); // electric indigo
  static const Color accent    = Color(0xFF10B981); // emerald green
  static const Color gold      = Color(0xFFF59E0B); // amber / streak
  static const Color coral     = Color(0xFFFF6B6B); // soft red
  static const Color violet    = Color(0xFF8B5CF6); // violet / vocabulary
  static const Color sky       = Color(0xFF38BDF8); // sky blue / reading

  // ─── Dark background layers ───────────────────────────────────────────────
  static const Color bg0       = Color(0xFF070B17); // deepest navy
  static const Color bg1       = Color(0xFF0D1426); // dark navy
  static const Color bg2       = Color(0xFF111827); // card surface
  static const Color bg3       = Color(0xFF1A2236); // elevated surface

  // ─── Glass / borders ─────────────────────────────────────────────────────
  static const Color glassDark       = Color(0xFF14213D);
  static const Color borderDark      = Color(0x26FFFFFF); // white 15%
  static const Color borderAccent    = Color(0x4010B981); // accent 25%
  static const Color borderPrimary   = Color(0x401337EC); // primary 25%

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BAD3);
  static const Color textMuted     = Color(0xFF6B7494);

  // ─── Band score colours ───────────────────────────────────────────────────
  static Color bandColor(double band) {
    if (band >= 7.5) return const Color(0xFF10B981); // expert → emerald
    if (band >= 6.0) return const Color(0xFF38BDF8); // competent → sky
    if (band >= 4.5) return const Color(0xFFF59E0B); // developing → amber
    return const Color(0xFFFF6B6B);                  // beginner → coral
  }

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient darkMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bg0, bg1, Color(0xFF0A1628)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1337EC), Color(0xFF5B21B6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF0891B2)],
  );

  static const LinearGradient readingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1337EC), Color(0xFF0891B2)],
  );

  static const LinearGradient writingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  static const LinearGradient vocabularyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  static const LinearGradient progressGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
}
