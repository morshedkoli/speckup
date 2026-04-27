import 'package:flutter/material.dart';
import 'app_colors.dart';

class GlassStyles {
  GlassStyles._();

  // ─── Brand colours (kept for back-compat) ────────────────────────────────
  static const Color primaryGreen = AppColors.accent;
  static const Color secondaryGreen = Color(0xFF34D399);

  // ─── Background gradients ─────────────────────────────────────────────────
  static const LinearGradient lightMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFECFDF5),
      Color(0xFFF8FAFC),
      Color(0xFFD1FAE5),
    ],
  );

  static const LinearGradient darkMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bg0, AppColors.bg1, Color(0xFF0A1628)],
  );

  // ─── Glass parameters ─────────────────────────────────────────────────────
  static const double blurSigma = 20.0;

  // Rounded-12 matching Stitch's ROUND_TWELVE
  static const BorderRadius defaultRadius =
      BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(20.0));

  // ─── Glass surface colours ────────────────────────────────────────────────
  static Color glassColorLight = Colors.white.withValues(alpha: 0.65);
  static Color glassColorDark  = AppColors.glassDark.withValues(alpha: 0.6);

  // ─── Glass borders ────────────────────────────────────────────────────────
  static Border glassBorderLight =
      Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5);
  static Border glassBorderDark =
      Border.all(color: AppColors.borderDark, width: 1.0);
  static Border glassBorderAccent =
      Border.all(color: AppColors.borderAccent, width: 1.0);
  static Border glassBorderPrimary =
      Border.all(color: AppColors.borderPrimary, width: 1.0);
}
