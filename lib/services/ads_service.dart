import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages AdMob ads with safe lifecycle handling, frequency caps,
/// and graceful failure when ads are unavailable.
class AdsService {
  // Google's official test ad unit IDs
  static String get _testInterstitialId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    return 'ca-app-pub-3940256099942544/4411468910'; // iOS fallback
  }

  static String get _testRewardedId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    return 'ca-app-pub-3940256099942544/1712485313'; // iOS fallback
  }

  // ---- CHANGE THESE FOR PRODUCTION ----
  // Replace with your real AdMob ad unit IDs before release.
  static const bool _useTestAds = true;
  static const String _prodInterstitialAndroid = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
  static const String _prodRewardedAndroid = 'YOUR_REWARDED_AD_UNIT_ID';
  // ---- END PRODUCTION CONFIG ----

  String get interstitialAdUnitId =>
      _useTestAds ? _testInterstitialId : _prodInterstitialAndroid;
  String get rewardedAdUnitId =>
      _useTestAds ? _testRewardedId : _prodRewardedAndroid;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  bool _initialized = false;
  bool _disposed = false;

  // Frequency control
  int _runsSinceLastInterstitial = 0;
  int _interstitialFrequency = 3;
  bool _justShowedRewarded = false;

  bool get isInterstitialReady => _isInterstitialReady && !_disposed;
  bool get isRewardedReady => _isRewardedReady && !_disposed;

  /// Initialize the Mobile Ads SDK.
  Future<void> init({int interstitialFrequency = 3}) async {
    _interstitialFrequency = interstitialFrequency;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('AdsService: Failed to initialize MobileAds: $e');
      _initialized = false;
    }
  }

  // --- Interstitial ---

  void _loadInterstitial() {
    if (!_initialized || _disposed) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            'AdsService: Interstitial failed to load: ${error.message}',
          );
          _isInterstitialReady = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Check whether an interstitial should show based on frequency cap.
  bool shouldShowInterstitial() {
    if (!_isInterstitialReady || _disposed) return false;
    if (_justShowedRewarded) {
      _justShowedRewarded = false;
      return false;
    }
    return _runsSinceLastInterstitial >= _interstitialFrequency;
  }

  /// Record a completed run for frequency tracking.
  void onRunCompleted() {
    _runsSinceLastInterstitial++;
  }

  /// Show an interstitial ad if eligible.
  void showInterstitial({VoidCallback? onDismissed}) {
    if (!_isInterstitialReady || _interstitialAd == null || _disposed) {
      onDismissed?.call();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialReady = false;
        _interstitialAd = null;
        _runsSinceLastInterstitial = 0;
        _loadInterstitial(); // Preload next
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdsService: Interstitial failed to show: ${error.message}');
        ad.dispose();
        _isInterstitialReady = false;
        _interstitialAd = null;
        _loadInterstitial();
        onDismissed?.call();
      },
    );
    _interstitialAd!.show();
  }

  // --- Rewarded ---

  void _loadRewarded() {
    if (!_initialized || _disposed) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            'AdsService: Rewarded ad failed to load: ${error.message}',
          );
          _isRewardedReady = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Show a rewarded ad. [onRewarded] is called ONLY after the user
  /// earns the reward (watched to completion).
  void showRewarded({
    required VoidCallback onRewarded,
    VoidCallback? onDismissed,
    VoidCallback? onFailed,
  }) {
    if (!_isRewardedReady || _rewardedAd == null || _disposed) {
      onFailed?.call();
      return;
    }

    bool rewardGranted = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isRewardedReady = false;
        _rewardedAd = null;
        _justShowedRewarded = true;
        _loadRewarded(); // Preload next
        if (rewardGranted) {
          onRewarded();
        }
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdsService: Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _isRewardedReady = false;
        _rewardedAd = null;
        _loadRewarded();
        onFailed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardGranted = true;
      },
    );
  }

  void dispose() {
    _disposed = true;
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialReady = false;
    _isRewardedReady = false;
  }
}
