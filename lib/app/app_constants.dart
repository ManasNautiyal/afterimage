/// Game-wide constants and configuration values for AFTERIMAGE.
class AppConstants {
  AppConstants._();

  // App identity
  static const String appName = 'AFTERIMAGE';
  static const String appTagline = 'Your past self is trying to stop you.';
  static const String appVersion = '1.0.0';

  // Storage keys (versioned with prefix)
  static const String keyPrefix = 'afterimage_v1_';
  static const String keyBestScore = '${keyPrefix}best_score';
  static const String keyBestDuration = '${keyPrefix}best_duration';
  static const String keyTotalCurrency = '${keyPrefix}total_currency';
  static const String keyOwnedSkins = '${keyPrefix}owned_skins';
  static const String keySelectedSkin = '${keyPrefix}selected_skin';
  static const String keySoundEnabled = '${keyPrefix}sound_enabled';
  static const String keyMusicEnabled = '${keyPrefix}music_enabled';
  static const String keyCompletedRuns = '${keyPrefix}completed_runs';

  // Ad configuration
  static const int interstitialFrequency = 3; // Show after every N runs
  static const int maxRevivesPerRun = 1;

  // Currency
  static const int currencyPerFragment = 1;
  static const double currencyPerSecondSurvived = 0.5;
  static const int bonusCurrencyMultiplier = 2; // Rewarded ad bonus

  // Skin prices
  static const int defaultSkinPrice = 0;
  static const List<int> skinPrices = [0, 50, 100, 150, 250];
}
