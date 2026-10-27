import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../app/app_theme.dart';
import '../game/afterimage_game.dart';
import '../game/game_state.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/pause_overlay.dart';

/// The gameplay screen hosting the Flame game with HUD and joystick overlay.
class GameplayScreen extends StatefulWidget {
  final StorageService storageService;
  final AudioService audioService;
  final VoidCallback onGameOver;
  final VoidCallback onMainMenu;

  const GameplayScreen({
    super.key,
    required this.storageService,
    required this.audioService,
    required this.onGameOver,
    required this.onMainMenu,
  });

  @override
  State<GameplayScreen> createState() => GameplayScreenState();
}

class GameplayScreenState extends State<GameplayScreen>
    with WidgetsBindingObserver {
  AfterimageGame? _game;
  bool _isPaused = false;
  bool _soundEnabled = true;
  int _displayScore = 0;
  double _displayTime = 0;
  int _displayFragments = 0;
  int _displayGhosts = 0;

  // Joystick state
  Offset? _joystickStart;
  Offset _joystickDelta = Offset.zero;
  static const double _joystickMaxRadius = 60;

  AfterimageGame? get game => _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _soundEnabled = widget.storageService.getSoundEnabled();
    _createGame();
  }

  void _createGame() {
    final skinIndex = widget.storageService.getSelectedSkin();
    _game = AfterimageGame(
      storageService: widget.storageService,
      audioService: widget.audioService,
      skinIndex: skinIndex,
      onGameOverCallback: () {
        if (mounted) {
          widget.onGameOver();
        }
      },
      onStateChanged: (state) {
        if (mounted) setState(() {});
      },
    );
  }

  void restartGame() {
    setState(() {
      _isPaused = false;
      _displayScore = 0;
      _displayTime = 0;
      _displayFragments = 0;
      _displayGhosts = 0;
      if (_game != null) {
        _game!.startNewRun();
      } else {
        _createGame();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_game?.state == GameState.playing) {
        _pauseGame();
      }
    }
  }

  void _pauseGame() {
    _game?.pauseGame();
    setState(() => _isPaused = true);
  }

  void _resumeGame() {
    _game?.resumeGame();
    setState(() => _isPaused = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateHUD() {
    if (_game == null || _game!.state != GameState.playing) return;
    setState(() {
      _displayScore = _game!.scoringSystem.score;
      _displayTime = _game!.scoringSystem.survivalTime;
      _displayFragments = _game!.scoringSystem.fragmentsCollected;
      _displayGhosts =
          _game!.ghosts.where((g) => g.isActive && g.hasSpawned).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Game
          if (_game != null) GameWidget(game: _game!),

          // HUD overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score and time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HudText(
                        label: 'SCORE',
                        value: '$_displayScore',
                        color: AppTheme.playerCyan,
                      ),
                      const SizedBox(height: 2),
                      _HudText(
                        label: 'TIME',
                        value: _formatTime(_displayTime),
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                  // Fragments and ghosts
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: AppTheme.fragmentGold,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_displayFragments',
                            style: const TextStyle(
                              color: AppTheme.fragmentGold,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: AppTheme.ghostViolet,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_displayGhosts',
                            style: const TextStyle(
                              color: AppTheme.ghostViolet,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pause button
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () {
                    if (_game?.state == GameState.playing) {
                      _pauseGame();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surface.withAlpha(150),
                    ),
                    child: const Icon(
                      Icons.pause,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Joystick touch area (bottom half of screen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: GestureDetector(
              onPanStart: (details) {
                _joystickStart = details.localPosition;
                _joystickDelta = Offset.zero;
              },
              onPanUpdate: (details) {
                if (_joystickStart == null) return;
                final delta = details.localPosition - _joystickStart!;
                final distance = delta.distance;
                if (distance > _joystickMaxRadius) {
                  _joystickDelta = Offset(
                    delta.dx / distance * _joystickMaxRadius,
                    delta.dy / distance * _joystickMaxRadius,
                  );
                } else {
                  _joystickDelta = delta;
                }
                final normalized = Offset(
                  _joystickDelta.dx / _joystickMaxRadius,
                  _joystickDelta.dy / _joystickMaxRadius,
                );
                _game?.onJoystickMove(Vector2(normalized.dx, normalized.dy));
                _updateHUD();
              },
              onPanEnd: (_) {
                _joystickStart = null;
                _joystickDelta = Offset.zero;
                _game?.onJoystickMove(Vector2.zero());
              },
              onPanCancel: () {
                _joystickStart = null;
                _joystickDelta = Offset.zero;
                _game?.onJoystickMove(Vector2.zero());
              },
              behavior: HitTestBehavior.translucent,
              child: CustomPaint(
                painter:
                    _joystickStart != null
                        ? _JoystickPainter(
                          center: _joystickStart!,
                          knob: _joystickStart! + _joystickDelta,
                          maxRadius: _joystickMaxRadius,
                        )
                        : null,
              ),
            ),
          ),

          // Periodic HUD update
          _HudUpdater(onTick: _updateHUD),

          // Pause overlay
          if (_isPaused)
            PauseOverlay(
              onResume: _resumeGame,
              onRestart: () {
                _isPaused = false;
                restartGame();
              },
              onMainMenu: widget.onMainMenu,
              soundEnabled: _soundEnabled,
              onToggleSound: () {
                setState(() {
                  _soundEnabled = !_soundEnabled;
                  widget.storageService.setSoundEnabled(_soundEnabled);
                  widget.audioService.setSoundEnabled(_soundEnabled);
                });
              },
            ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class _HudText extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HudText({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            color: color.withAlpha(150),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

/// Paints the virtual joystick when touch is active.
class _JoystickPainter extends CustomPainter {
  final Offset center;
  final Offset knob;
  final double maxRadius;

  _JoystickPainter({
    required this.center,
    required this.knob,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base circle
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..color = AppTheme.playerCyan.withAlpha(20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..color = AppTheme.playerCyan.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Knob
    canvas.drawCircle(
      knob,
      18,
      Paint()..color = AppTheme.playerCyan.withAlpha(80),
    );
    canvas.drawCircle(
      knob,
      12,
      Paint()..color = AppTheme.playerCyan.withAlpha(150),
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) {
    return center != oldDelegate.center || knob != oldDelegate.knob;
  }
}

/// Periodically updates HUD values.
class _HudUpdater extends StatefulWidget {
  final VoidCallback onTick;

  const _HudUpdater({required this.onTick});

  @override
  State<_HudUpdater> createState() => _HudUpdaterState();
}

class _HudUpdaterState extends State<_HudUpdater>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => widget.onTick());
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
