import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';

/// Settings screen with sound toggles and app info.
class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final AudioService audioService;
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.audioService,
    required this.onBack,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _musicEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = widget.storageService.getSoundEnabled();
    _musicEnabled = widget.storageService.getMusicEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final bestScore = widget.storageService.getBestScore();
    final bestDuration = widget.storageService.getBestDuration();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'SETTINGS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance header
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'AUDIO'),
                  _ToggleTile(
                    icon: Icons.volume_up,
                    label: 'Sound Effects',
                    value: _soundEnabled,
                    onChanged: (val) {
                      setState(() => _soundEnabled = val);
                      widget.storageService.setSoundEnabled(val);
                      widget.audioService.setSoundEnabled(val);
                    },
                  ),
                  _ToggleTile(
                    icon: Icons.music_note,
                    label: 'Music',
                    value: _musicEnabled,
                    onChanged: (val) {
                      setState(() => _musicEnabled = val);
                      widget.storageService.setMusicEnabled(val);
                      widget.audioService.setMusicEnabled(val);
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'STATISTICS'),
                  _InfoTile(
                    icon: Icons.emoji_events,
                    label: 'Best Score',
                    value: '$bestScore',
                    color: AppTheme.playerCyan,
                  ),
                  _InfoTile(
                    icon: Icons.timer,
                    label: 'Best Survival',
                    value: _formatDuration(bestDuration),
                    color: AppTheme.accentViolet,
                  ),
                  _InfoTile(
                    icon: Icons.bolt,
                    label: 'Total Currency',
                    value: '${widget.storageService.getTotalCurrency()}',
                    color: AppTheme.fragmentGold,
                  ),
                  _InfoTile(
                    icon: Icons.replay,
                    label: 'Total Runs',
                    value: '${widget.storageService.getCompletedRuns()}',
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'ABOUT'),
                  _InfoTile(
                    icon: Icons.info_outline,
                    label: 'Version',
                    value: '1.0.0',
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '—';
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.playerCyan.withAlpha(180),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.surface,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.playerCyan,
            inactiveTrackColor: AppTheme.surfaceLight,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.surface,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
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
      ),
    );
  }
}
