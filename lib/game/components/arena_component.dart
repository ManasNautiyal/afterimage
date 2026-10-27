import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import '../game_config.dart';
import '../afterimage_game.dart';

/// The arena boundary with neon grid and border.
class ArenaComponent extends PositionComponent
    with HasGameReference<AfterimageGame> {
  ui.Rect arenaBounds = const ui.Rect.fromLTRB(20, 100, 380, 700);

  @override
  Future<void> onLoad() async {
    updateBounds();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    updateBounds();
  }

  void updateBounds() {
    final gameSize = isMounted ? game.size : null;
    if (gameSize != null && gameSize.x > 80 && gameSize.y > 160) {
      final padding = GameConfig.arenaPadding;
      // Leave space at top for HUD
      final topPadding = padding + 80;
      arenaBounds = ui.Rect.fromLTRB(
        padding,
        topPadding,
        gameSize.x - padding,
        gameSize.y - padding,
      );
      size = Vector2(arenaBounds.width, arenaBounds.height);
      position = Vector2(arenaBounds.left, arenaBounds.top);
    }
  }

  /// Clamp a position to be within arena bounds, accounting for entity radius.
  Vector2 clampToArena(Vector2 pos, double radius) {
    final minX = arenaBounds.left + radius;
    final maxX = arenaBounds.right - radius;
    final minY = arenaBounds.top + radius;
    final maxY = arenaBounds.bottom - radius;

    final clampedX = minX < maxX ? pos.x.clamp(minX, maxX) : arenaBounds.center.dx;
    final clampedY = minY < maxY ? pos.y.clamp(minY, maxY) : arenaBounds.center.dy;

    return Vector2(clampedX, clampedY);
  }

  /// Get a random position inside the arena with margin.
  Vector2 randomPosition(Random rng, {double margin = 20}) {
    final w = arenaBounds.width - 2 * margin;
    final h = arenaBounds.height - 2 * margin;
    if (w <= 0 || h <= 0) {
      return Vector2(arenaBounds.center.dx, arenaBounds.center.dy);
    }
    return Vector2(
      arenaBounds.left + margin + rng.nextDouble() * w,
      arenaBounds.top + margin + rng.nextDouble() * h,
    );
  }

  /// Get a random position at least [minDist] away from [avoidPos].
  Vector2 randomPositionAwayFrom(
    Random rng,
    Vector2 avoidPos,
    double minDist, {
    double margin = 20,
    int maxAttempts = 30,
  }) {
    for (int i = 0; i < maxAttempts; i++) {
      final pos = randomPosition(rng, margin: margin);
      if (pos.distanceTo(avoidPos) >= minDist) return pos;
    }
    return randomPosition(rng, margin: margin); // Fallback
  }

  @override
  void render(ui.Canvas canvas) {
    // Draw dark background
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint()..color = const ui.Color(0xFF080818),
    );

    // Draw grid
    final gridPaint =
        ui.Paint()
          ..color = const ui.Color(0x0D00E5FF)
          ..strokeWidth = 0.5;

    final spacing = GameConfig.arenaGridSpacing;
    for (double x = 0; x < size.x; x += spacing) {
      canvas.drawLine(ui.Offset(x, 0), ui.Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += spacing) {
      canvas.drawLine(ui.Offset(0, y), ui.Offset(size.x, y), gridPaint);
    }

    // Draw border glow
    final borderPaint =
        ui.Paint()
          ..color = const ui.Color(0xFF00E5FF)
          ..strokeWidth = 2.0
          ..style = ui.PaintingStyle.stroke;

    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.x, size.y), borderPaint);

    // Outer glow
    final glowPaint =
        ui.Paint()
          ..color = const ui.Color(0x3300E5FF)
          ..strokeWidth = 6.0
          ..style = ui.PaintingStyle.stroke
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 4);

    canvas.drawRect(
      ui.Rect.fromLTWH(-2, -2, size.x + 4, size.y + 4),
      glowPaint,
    );
  }
}
