import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../models/run_result.dart';
import '../widgets/neon_button.dart';
import '../widgets/score_display.dart';

/// Game over screen showing results, records, and action buttons.
class GameOverScreen extends StatefulWidget {
  final RunResult result;
  final bool canRevive;
  final bool rewardedAdReady;
  final VoidCallback onRetry;
  final VoidCallback onMainMenu;
  final VoidCallback? onRevive;
  final VoidCallback? onBonusCurrency;

  const GameOverScreen({
    super.key,
    required this.result,
    required this.canRevive,
    required this.rewardedAdReady,
    required this.onRetry,
    required this.onMainMenu,
    this.onRevive,
    this.onBonusCurrency,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(200),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withAlpha(245),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          widget.result.isNewBestScore
                              ? AppTheme.fragmentGold.withAlpha(80)
                              : AppTheme.playerCyan.withAlpha(40),
                      width: widget.result.isNewBestScore ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.result.isNewBestScore
                                ? AppTheme.fragmentGold
                                : AppTheme.playerCyan)
                            .withAlpha(25),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: AppTheme.hazardRed,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Score
                      ScoreDisplay(
                        score: widget.result.score,
                        isNewRecord: widget.result.isNewBestScore,
                      ),
                      const SizedBox(height: 20),

                      // Stats grid
                      _StatRow(
                        icon: Icons.timer_outlined,
                        label: 'Survival',
                        value: _formatDuration(widget.result.survivalTime),
                        color: AppTheme.playerCyan,
                        isRecord: widget.result.isNewBestDuration,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: Icons.bolt,
                        label: 'Fragments',
                        value: '${widget.result.fragmentsCollected}',
                        color: AppTheme.fragmentGold,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: Icons.person_outline,
                        label: 'Ghosts',
                        value: '${widget.result.ghostsSpawned}',
                        color: AppTheme.ghostViolet,
                      ),
                      const SizedBox(height: 16),

                      // Currency earned
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.fragmentGold.withAlpha(15),
                          border: Border.all(
                            color: AppTheme.fragmentGold.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: AppTheme.fragmentGold,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${widget.result.currencyEarned}',
                              style: const TextStyle(
                                color: AppTheme.fragmentGold,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Retry button (always available, no ad required)
                      NeonButton(
                        text: 'RETRY',
                        onPressed: widget.onRetry,
                        color: AppTheme.playerCyan,
                        width: 200,
                        height: 50,
                        icon: Icons.replay,
                      ),
                      const SizedBox(height: 12),

                      // Revive option (rewarded ad)
                      if (widget.canRevive)
                        NeonButton(
                          text: 'REVIVE',
                          onPressed: () => widget.onRevive?.call(),
                          color: AppTheme.success,
                          width: 200,
                          height: 44,
                          fontSize: 14,
                          icon: Icons.favorite,
                        ),
                      if (widget.canRevive)
                        const SizedBox(height: 8),

                      // Bonus currency (rewarded ad)
                      if (widget.onBonusCurrency != null)
                        NeonButton(
                          text: '2x CURRENCY',
                          onPressed: () => widget.onBonusCurrency?.call(),
                          color: AppTheme.fragmentGold,
                          width: 200,
                          height: 44,
                          fontSize: 14,
                          icon: Icons.ondemand_video,
                        ),
                      if (widget.onBonusCurrency != null)
                        const SizedBox(height: 8),

                      NeonButton(
                        text: 'MENU',
                        onPressed: widget.onMainMenu,
                        color: AppTheme.textMuted,
                        width: 200,
                        height: 44,
                        fontSize: 14,
                        icon: Icons.home_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    final ms = ((seconds % 1) * 10).toInt().toString();
    return '$mins:$secs.$ms';
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isRecord;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isRecord = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        const Spacer(),
        if (isRecord)
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppTheme.fragmentGold.withAlpha(30),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: AppTheme.fragmentGold,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
