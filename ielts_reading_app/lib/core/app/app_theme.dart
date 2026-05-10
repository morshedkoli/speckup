import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const primary = AppColors.primary;
  static const accent = AppColors.success;

  static const primaryGradient = AppColors.primaryGradient;

  // ─── Light theme ──────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        secondary: accent,
        surface: Colors.white,
        surfaceContainerLow: AppColors.zinc50,
      ),
    );
    return _applyShared(base, Brightness.light);
  }

  // ─── Dark theme ───────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        secondary: accent,
        surface: AppColors.zinc950,
        surfaceContainerLow: AppColors.zinc900,
      ),
    );
    return _applyShared(base, Brightness.dark);
  }

  // ─── Shared configuration ─────────────────────────────────────────────────

  static ThemeData _applyShared(ThemeData base, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = base.colorScheme;
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? AppColors.zinc950 : Colors.white,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.zinc950 : Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.zinc50 : AppColors.zinc950,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: isDark ? AppColors.zinc50 : AppColors.zinc950,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.zinc900 : AppColors.zinc50,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.zinc800 : AppColors.zinc200,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.zinc800 : AppColors.zinc200,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(
            color: isDark ? AppColors.zinc700 : AppColors.zinc300,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.zinc900 : AppColors.zinc50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.zinc700 : AppColors.zinc300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.zinc700 : AppColors.zinc300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: scheme.primary,
        labelColor: scheme.primary,
        unselectedLabelColor: isDark ? AppColors.zinc400 : AppColors.zinc500,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: isDark ? AppColors.zinc800 : AppColors.zinc200,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? AppColors.zinc950 : Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: isDark ? AppColors.zinc700 : AppColors.zinc300,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.zinc900 : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
