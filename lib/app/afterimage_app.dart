import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../models/run_result.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/ads_service.dart';
import '../screens/main_menu_screen.dart';
import '../screens/gameplay_screen.dart';
import '../screens/game_over_screen.dart';
import '../screens/skins_screen.dart';
import '../screens/settings_screen.dart';

/// Root application widget managing screen navigation.
class AfterimageApp extends StatefulWidget {
  final StorageService storageService;
  final AudioService audioService;
  final AdsService adsService;

  const AfterimageApp({
    super.key,
    required this.storageService,
    required this.audioService,
    required this.adsService,
  });

  @override
  State<AfterimageApp> createState() => _AfterimageAppState();
}

enum AppScreen { mainMenu, playing, gameOver, skins, settings }

class _AfterimageAppState extends State<AfterimageApp> {
  AppScreen _currentScreen = AppScreen.mainMenu;
  RunResult? _lastResult;
  final GlobalKey<GameplayScreenState> _gameKey = GlobalKey();
  bool _bonusCurrencyGranted = false;

  void _navigateTo(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
      if (screen == AppScreen.playing) {
        _lastResult = null;
        _bonusCurrencyGranted = false;
      }
    });
  }

  void _onGameOver() {
    final game = _gameKey.currentState?.game;
    if (game == null) return;

    final result = game.getRunResult();
    game.saveRunResults();
    widget.adsService.onRunCompleted();

    setState(() {
      _lastResult = result;
      _currentScreen = AppScreen.gameOver;
    });
  }

  void _onRetry() {
    // Check if we should show an interstitial
    if (widget.adsService.shouldShowInterstitial()) {
      widget.adsService.showInterstitial(
        onDismissed: () {
          _startNewGame();
        },
      );
    } else {
      _startNewGame();
    }
  }

  void _startNewGame() {
    _navigateTo(AppScreen.playing);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameKey.currentState?.restartGame();
    });
  }

  void _onRevive() {
    final game = _gameKey.currentState?.game;
    if (game == null || !game.canRevive) return;

    widget.adsService.showRewarded(
      onRewarded: () {
        game.revivePlayer();
        setState(() => _currentScreen = AppScreen.playing);
      },
      onFailed: () {
        // Show a message that ad wasn't available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad not available. Try again later.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _onBonusCurrency() {
    if (_bonusCurrencyGranted || _lastResult == null) return;

    widget.adsService.showRewarded(
      onRewarded: () {
        if (!_bonusCurrencyGranted) {
          _bonusCurrencyGranted = true;
          final bonus = _lastResult!.currencyEarned;
          widget.storageService.addCurrency(bonus);
          setState(() {});
        }
      },
      onFailed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad not available. Try again later.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFTERIMAGE',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.mainMenu:
        return MainMenuScreen(
          storageService: widget.storageService,
          audioService: widget.audioService,
          onPlay: () => _startNewGame(),
          onSkins: () => _navigateTo(AppScreen.skins),
          onSettings: () => _navigateTo(AppScreen.settings),
        );

      case AppScreen.playing:
        return GameplayScreen(
          key: _gameKey,
          storageService: widget.storageService,
          audioService: widget.audioService,
          onGameOver: _onGameOver,
          onMainMenu: () => _navigateTo(AppScreen.mainMenu),
        );

      case AppScreen.gameOver:
        return Stack(
          children: [
            // Game is still visible behind the overlay
            GameplayScreen(
              key: _gameKey,
              storageService: widget.storageService,
              audioService: widget.audioService,
              onGameOver: _onGameOver,
              onMainMenu: () => _navigateTo(AppScreen.mainMenu),
            ),
            if (_lastResult != null)
              GameOverScreen(
                result: _lastResult!,
                canRevive: _gameKey.currentState?.game?.canRevive ?? false,
                rewardedAdReady: widget.adsService.isRewardedReady,
                onRetry: _onRetry,
                onMainMenu: () => _navigateTo(AppScreen.mainMenu),
                onRevive: _onRevive,
                onBonusCurrency:
                    _bonusCurrencyGranted ? null : _onBonusCurrency,
              ),
          ],
        );

      case AppScreen.skins:
        return SkinsScreen(
          storageService: widget.storageService,
          audioService: widget.audioService,
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );

      case AppScreen.settings:
        return SettingsScreen(
          storageService: widget.storageService,
          audioService: widget.audioService,
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
    }
  }
}
