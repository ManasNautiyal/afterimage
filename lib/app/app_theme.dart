import 'package:flutter/material.dart';

/// Neon arcade theme for AFTERIMAGE.
class AppTheme {
  AppTheme._();

  // Core colors
  static const Color background = Color(0xFF0A0A1A);
  static const Color surface = Color(0xFF12122A);
  static const Color surfaceLight = Color(0xFF1A1A3A);
  static const Color playerCyan = Color(0xFF00E5FF);
  static const Color ghostViolet = Color(0xFF9C27B0);
  static const Color ghostBlue = Color(0xFF7C4DFF);
  static const Color hazardRed = Color(0xFFFF1744);
  static const Color hazardOrange = Color(0xFFFF6D00);
  static const Color fragmentGold = Color(0xFFFFD740);
  static const Color fragmentYellow = Color(0xFFFFEA00);
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentViolet = Color(0xFFAB47BC);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x80FFFFFF);
  static const Color success = Color(0xFF00E676);
  static const Color arenaGrid = Color(0x1A00E5FF);
  static const Color arenaBorder = Color(0xFF00E5FF);

  // Ghost colors for multiple ghosts
  static const List<Color> ghostColors = [
    Color(0xFF9C27B0), // Purple
    Color(0xFF7C4DFF), // Deep purple
    Color(0xFF448AFF), // Blue
    Color(0xFFE040FB), // Pink
    Color(0xFF536DFE), // Indigo
    Color(0xFF18FFFF), // Cyan-ish
  ];

  // Skin colors
  static const List<Color> skinColors = [
    Color(0xFF00E5FF), // Cyan (default)
    Color(0xFFFF4081), // Pink
    Color(0xFF76FF03), // Lime
    Color(0xFFFFD740), // Gold
    Color(0xFFE040FB), // Magenta
  ];

  static const List<String> skinNames = [
    'Neon Cyan',
    'Hot Pink',
    'Toxic Lime',
    'Golden Hour',
    'Magenta Pulse',
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: playerCyan,
        secondary: accentViolet,
        surface: surface,
        error: hazardRed,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textSecondary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: playerCyan,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
