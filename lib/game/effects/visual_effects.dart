import 'dart:ui' as ui;

/// Utility for lightweight visual effects used across the game.
class VisualEffects {
  VisualEffects._();

  /// Create a neon glow paint with the given color and blur radius.
  static ui.Paint neonGlow(
    ui.Color color,
    double blurRadius, {
    double alpha = 0.3,
  }) {
    return ui.Paint()
      ..color = color.withAlpha((alpha * 255).toInt())
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blurRadius);
  }

  /// Create a radial gradient paint for a glowing circle.
  static ui.Paint radialGlow(ui.Color color, ui.Offset center, double radius) {
    final gradient = ui.Gradient.radial(
      center,
      radius,
      [color.withAlpha(200), color.withAlpha(80), color.withAlpha(0)],
      [0.0, 0.5, 1.0],
    );
    return ui.Paint()..shader = gradient;
  }
}
