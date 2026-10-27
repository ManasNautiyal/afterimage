import 'package:flutter/material.dart';
import '../app/app_theme.dart';

/// Animated score display with optional new-record highlight.
class ScoreDisplay extends StatelessWidget {
  final int score;
  final bool isNewRecord;

  const ScoreDisplay({
    super.key,
    required this.score,
    this.isNewRecord = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isNewRecord)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppTheme.fragmentGold, AppTheme.hazardOrange],
              ),
            ),
            child: const Text(
              '★ NEW RECORD ★',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        if (isNewRecord) const SizedBox(height: 8),
        Text(
          '$score',
          style: TextStyle(
            color: isNewRecord ? AppTheme.fragmentGold : AppTheme.textPrimary,
            fontSize: isNewRecord ? 48 : 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows:
                isNewRecord
                    ? [
                      const Shadow(
                        color: AppTheme.fragmentGold,
                        blurRadius: 20,
                      ),
                    ]
                    : null,
          ),
        ),
      ],
    );
  }
}
