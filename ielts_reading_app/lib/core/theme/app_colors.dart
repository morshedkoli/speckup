import 'package:flutter/material.dart';

/// Zinc-based color system inspired by shadcn/ui.
///
/// Flat, minimal, high-contrast palette that works in both light and dark modes.
/// Primary accent: blue. Neutral base: zinc.
class AppColors {
  AppColors._();

  // ─── Primary / Accent ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB); // blue-600
  static const Color primaryLight = Color(0xFF3B82F6); // blue-500
  static const Color primaryMuted = Color(0xFFDBEAFE); // blue-100
  static const Color primaryDarkMuted = Color(0xFF1E3A5F); // custom dark blue

  // ─── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E); // green-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color destructive = Color(0xFFEF4444); // red-500
  static const Color info = Color(0xFF0EA5E9); // sky-500
  static const Color violet = Color(0xFF8B5CF6); // violet-500

  // ─── Zinc (Light) ──────────────────────────────────────────────────────────
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc950 = Color(0xFF09090B);

  // ─── Feature colours ───────────────────────────────────────────────────────
  static const Color reading = Color(0xFF2563EB); // blue
  static const Color writing = Color(0xFFF97316); // orange
  static const Color vocabulary = Color(0xFF8B5CF6); // violet
  static const Color synonyms = Color(0xFF14B8A6); // teal
  static const Color essayAi = Color(0xFF6366F1); // indigo

  // ─── Band score ────────────────────────────────────────────────────────────
  static Color bandColor(double band) {
    if (band >= 7.5) return success;
    if (band >= 6.0) return info;
    if (band >= 4.5) return warning;
    return destructive;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Card background for current brightness.
  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? zinc900 : zinc50;

  /// Elevated card surface.
  static Color cardBgHover(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? zinc800 : zinc100;

  /// Border for cards and containers.
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? zinc800 : zinc200;

  /// Muted/secondary text.
  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? zinc400 : zinc500;

  /// Standard text.
  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? zinc50 : zinc950;

  // ─── Backward-compat aliases (for screens not yet migrated) ────────────────
  static const Color accent = success;
  static const Color gold = warning;
  static const Color coral = destructive;
  static const Color sky = info;

  // Dark-mode layers (kept for gradual migration)
  static const Color bg0 = zinc950;
  static const Color bg1 = Color(0xFF0D1117);
  static const Color bg2 = zinc900;
  static const Color bg3 = zinc800;
  static const Color glassDark = zinc900;

  static const Color borderDark = Color(0xFF27272A);
  static const Color borderAccent = Color(0x4022C55E);
  static const Color borderPrimary = Color(0x402563EB);

  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  @Deprecated('Use textMuted(context) instead')
  static const Color textMutedStatic = Color(0xFF71717A);

  // Legacy gradients — kept for backward-compat, use sparingly
  static const LinearGradient darkMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [zinc950, Color(0xFF0D1117), Color(0xFF0A1628)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF0891B2)],
  );

  static const LinearGradient readingGradient = primaryGradient;

  static const LinearGradient writingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  );

  static const LinearGradient vocabularyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  static const LinearGradient progressGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF059669)],
  );
}
