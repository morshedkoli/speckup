class AppConstants {
  AppConstants._(); // Private constructor

  // Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Layout bounds
  static const double maxContentWidth = 800.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;

  // Storage keys
  static const String googleAiApiKeyStorageKey = 'GOOGLE_AI_API_KEY';

  // Hardcoded OpenRouter API key (fallback — replace with your key)
  static const String openRouterApiKey =
      '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';
}
