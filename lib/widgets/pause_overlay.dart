import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../widgets/neon_button.dart';

/// Pause overlay with resume, restart, menu, and sound toggle.
class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final bool soundEnabled;
  final VoidCallback onToggleSound;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onMainMenu,
    required this.soundEnabled,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(240),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.playerCyan.withAlpha(60)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.playerCyan.withAlpha(20),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 32),
              NeonButton(
                text: 'RESUME',
                onPressed: onResume,
                color: AppTheme.playerCyan,
              ),
              const SizedBox(height: 12),
              NeonButton(
                text: 'RESTART',
                onPressed: onRestart,
                color: AppTheme.accentViolet,
              ),
              const SizedBox(height: 12),
              NeonButton(
                text: 'MAIN MENU',
                onPressed: onMainMenu,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 20),
              IconButton(
                onPressed: onToggleSound,
                icon: Icon(
                  soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: AppTheme.textSecondary,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
