import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design system tokens for surfaces, borders, and radii.
///
/// The glass naming is kept for backward-compat but these are now flat styles.
class GlassStyles {
  GlassStyles._();

  // ─── Brand colours ─────────────────────────────────────────────────────────
  static const Color primaryGreen = AppColors.success;
  static const Color secondaryGreen = Color(0xFF34D399);

  // ─── Radii ─────────────────────────────────────────────────────────────────
  static const BorderRadius defaultRadius =
      BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(12.0));

  // ─── Borders ───────────────────────────────────────────────────────────────
  static Border glassBorderLight =
      Border.all(color: AppColors.zinc200, width: 1.0);
  static Border glassBorderDark =
      Border.all(color: AppColors.zinc800, width: 1.0);
  static Border glassBorderAccent =
      Border.all(color: AppColors.borderAccent, width: 1.0);
  static Border glassBorderPrimary =
      Border.all(color: AppColors.borderPrimary, width: 1.0);

  // ─── Surface colours ───────────────────────────────────────────────────────
  static Color glassColorLight = AppColors.zinc50;
  static Color glassColorDark = AppColors.zinc900;

  // Kept for compat — no blur in new design
  static const double blurSigma = 0;
}
