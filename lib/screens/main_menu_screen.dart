import 'dart:math';
import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../app/app_constants.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/neon_button.dart';
import '../widgets/currency_display.dart';

/// Main menu screen with animated background and navigation.
class MainMenuScreen extends StatefulWidget {
  final StorageService storageService;
  final AudioService audioService;
  final VoidCallback onPlay;
  final VoidCallback onSkins;
  final VoidCallback onSettings;

  const MainMenuScreen({
    super.key,
    required this.storageService,
    required this.audioService,
    required this.onPlay,
    required this.onSkins,
    required this.onSettings,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _titleScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _titleScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bestScore = widget.storageService.getBestScore();
    final currency = widget.storageService.getTotalCurrency();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _MenuBackgroundPainter(_floatController),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: _titleScale,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _titleScale.value,
                        child: ShaderMask(
                          shaderCallback:
                              (bounds) => const LinearGradient(
                                colors: [
                                  AppTheme.playerCyan,
                                  AppTheme.accentViolet,
                                  AppTheme.playerCyan,
                                ],
                              ).createShader(bounds),
                          child: const Text(
                            'AFTERIMAGE',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (bestScore > 0) ...[
                    const Text(
                      'BEST SCORE',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$bestScore',
                      style: const TextStyle(
                        color: AppTheme.playerCyan,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  CurrencyDisplay(amount: currency, fontSize: 18),
                  const Spacer(flex: 1),
                  NeonButton(
                    text: 'PLAY',
                    onPressed: widget.onPlay,
                    width: 200,
                    height: 56,
                    fontSize: 20,
                    icon: Icons.play_arrow_rounded,
                  ),
                  const SizedBox(height: 16),
                  NeonButton(
                    text: 'SKINS',
                    onPressed: widget.onSkins,
                    color: AppTheme.accentViolet,
                    width: 180,
                    height: 48,
                    fontSize: 15,
                    icon: Icons.palette_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          final current =
                              widget.storageService.getSoundEnabled();
                          widget.storageService.setSoundEnabled(!current);
                          widget.audioService.setSoundEnabled(!current);
                          setState(() {});
                        },
                        icon: Icon(
                          widget.storageService.getSoundEnabled()
                              ? Icons.volume_up
                              : Icons.volume_off,
                          color: AppTheme.textSecondary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: widget.onSettings,
                        icon: const Icon(
                          Icons.settings,
                          color: AppTheme.textSecondary,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_FloatingDot> _dots;

  _MenuBackgroundPainter(this.animation)
    : _dots = List.generate(
        20,
        (i) => _FloatingDot(
          x: Random(i).nextDouble(),
          y: Random(i * 3 + 7).nextDouble(),
          radius: 1.0 + Random(i * 2).nextDouble() * 2,
          speed: 0.2 + Random(i * 5).nextDouble() * 0.5,
        ),
      ),
      super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final dot in _dots) {
      final y = (dot.y + t * dot.speed) % 1.0;
      canvas.drawCircle(
        Offset(dot.x * size.width, y * size.height),
        dot.radius,
        Paint()..color = AppTheme.playerCyan.withAlpha(30),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FloatingDot {
  final double x, y, radius, speed;
  const _FloatingDot({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
  });
}
