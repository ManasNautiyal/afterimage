import 'package:shared_preferences/shared_preferences.dart';
import '../app/app_constants.dart';
import '../models/player_stats.dart';

/// Local storage service using SharedPreferences.
/// Handles all persistent data with safe defaults and validation.
class StorageService {
  SharedPreferences? _prefs;

  /// Whether the service has been initialized.
  bool get isInitialized => _prefs != null;

  /// Initialize SharedPreferences. Call once at app start.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// For testing: inject a mock SharedPreferences instance.
  void initWithPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  SharedPreferences get _safePrefs {
    assert(
      _prefs != null,
      'StorageService not initialized. Call init() first.',
    );
    return _prefs!;
  }

  // --- Best Score ---

  int getBestScore() {
    final val = _safePrefs.getInt(AppConstants.keyBestScore) ?? 0;
    return val < 0 ? 0 : val;
  }

  Future<bool> setBestScore(int score) {
    if (score < 0) score = 0;
    return _safePrefs.setInt(AppConstants.keyBestScore, score);
  }

  // --- Best Duration ---

  double getBestDuration() {
    final val = _safePrefs.getDouble(AppConstants.keyBestDuration) ?? 0.0;
    return val < 0 ? 0.0 : val;
  }

  Future<bool> setBestDuration(double duration) {
    if (duration < 0) duration = 0.0;
    return _safePrefs.setDouble(AppConstants.keyBestDuration, duration);
  }

  // --- Currency ---

  int getTotalCurrency() {
    final val = _safePrefs.getInt(AppConstants.keyTotalCurrency) ?? 0;
    return val < 0 ? 0 : val;
  }

  Future<bool> setTotalCurrency(int currency) {
    if (currency < 0) currency = 0;
    return _safePrefs.setInt(AppConstants.keyTotalCurrency, currency);
  }

  Future<bool> addCurrency(int amount) async {
    final current = getTotalCurrency();
    return setTotalCurrency(current + amount);
  }

  Future<bool> deductCurrency(int amount) async {
    final current = getTotalCurrency();
    if (current < amount) return false;
    return setTotalCurrency(current - amount);
  }

  // --- Skins ---

  Set<int> getOwnedSkins() {
    final list = _safePrefs.getStringList(AppConstants.keyOwnedSkins);
    if (list == null || list.isEmpty) return {0}; // Default skin always owned
    final skins =
        list.map((s) => int.tryParse(s) ?? -1).where((i) => i >= 0).toSet();
    skins.add(0); // Ensure default skin
    return skins;
  }

  Future<bool> setOwnedSkins(Set<int> skins) {
    skins.add(0); // Always own default
    return _safePrefs.setStringList(
      AppConstants.keyOwnedSkins,
      skins.map((s) => s.toString()).toList(),
    );
  }

  Future<bool> unlockSkin(int skinId, int price) async {
    final currency = getTotalCurrency();
    if (currency < price) return false;

    final skins = getOwnedSkins();
    if (skins.contains(skinId)) return true; // Already owned

    skins.add(skinId);
    final saved = await setOwnedSkins(skins);
    if (!saved) return false;

    return deductCurrency(price);
  }

  int getSelectedSkin() {
    return _safePrefs.getInt(AppConstants.keySelectedSkin) ?? 0;
  }

  Future<bool> setSelectedSkin(int skinId) {
    final owned = getOwnedSkins();
    if (!owned.contains(skinId)) return Future.value(false);
    return _safePrefs.setInt(AppConstants.keySelectedSkin, skinId);
  }

  // --- Sound ---

  bool getSoundEnabled() {
    return _safePrefs.getBool(AppConstants.keySoundEnabled) ?? true;
  }

  Future<bool> setSoundEnabled(bool enabled) {
    return _safePrefs.setBool(AppConstants.keySoundEnabled, enabled);
  }

  bool getMusicEnabled() {
    return _safePrefs.getBool(AppConstants.keyMusicEnabled) ?? true;
  }

  Future<bool> setMusicEnabled(bool enabled) {
    return _safePrefs.setBool(AppConstants.keyMusicEnabled, enabled);
  }

  // --- Run Counter ---

  int getCompletedRuns() {
    return _safePrefs.getInt(AppConstants.keyCompletedRuns) ?? 0;
  }

  Future<bool> incrementCompletedRuns() async {
    final current = getCompletedRuns();
    return _safePrefs.setInt(AppConstants.keyCompletedRuns, current + 1);
  }

  // --- Aggregate ---

  PlayerStats loadPlayerStats() {
    return PlayerStats(
      bestScore: getBestScore(),
      bestDuration: getBestDuration(),
      totalCurrency: getTotalCurrency(),
      ownedSkins: getOwnedSkins(),
      selectedSkin: getSelectedSkin(),
    );
  }

  /// Save end-of-run results. Returns updated PlayerStats.
  Future<PlayerStats> saveRunResult({
    required int score,
    required double duration,
    required int currencyEarned,
  }) async {
    final oldBest = getBestScore();
    final oldDuration = getBestDuration();

    if (score > oldBest) {
      await setBestScore(score);
    }
    if (duration > oldDuration) {
      await setBestDuration(duration);
    }
    await addCurrency(currencyEarned);
    await incrementCompletedRuns();

    return loadPlayerStats();
  }
}
