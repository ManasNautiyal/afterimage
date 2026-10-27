import 'package:flutter/material.dart';
import '../app/app_theme.dart';

/// Displays the player's currency with a coin icon.
class CurrencyDisplay extends StatelessWidget {
  final int amount;
  final double fontSize;

  const CurrencyDisplay({super.key, required this.amount, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surface.withAlpha(200),
        border: Border.all(color: AppTheme.fragmentGold.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: AppTheme.fragmentGold, size: fontSize + 4),
          const SizedBox(width: 4),
          Text(
            '$amount',
            style: TextStyle(
              color: AppTheme.fragmentGold,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
