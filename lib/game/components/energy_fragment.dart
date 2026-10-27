import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game_config.dart';
import '../afterimage_game.dart';

/// Collectible energy fragment with pulsing animation.
class EnergyFragment extends PositionComponent
    with HasGameReference<AfterimageGame>, CollisionCallbacks {
  double _pulsePhase = 0.0;
  double _rotationAngle = 0.0;
  bool _collected = false;

  bool get isCollected => _collected;

  EnergyFragment();

  @override
  Future<void> onLoad() async {
    size = Vector2.all(GameConfig.fragmentRadius * 2);
    anchor = Anchor.center;
    _pulsePhase = Random().nextDouble() * pi * 2;
    add(
      CircleHitbox(
        radius: GameConfig.fragmentHitboxRadius,
        position: Vector2.all(GameConfig.fragmentRadius),
        anchor: Anchor.center,
        isSolid: true,
      ),
    );
  }

  void collect() {
    _collected = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;
    _pulsePhase += dt * 4;
    _rotationAngle += dt * 1.5;
  }

  @override
  void render(ui.Canvas canvas) {
    if (_collected) return;

    final center = ui.Offset(
      GameConfig.fragmentRadius,
      GameConfig.fragmentRadius,
    );
    final radius = GameConfig.fragmentRadius;
    final pulse = 0.8 + 0.2 * sin(_pulsePhase);

    // Outer glow
    canvas.drawCircle(
      center,
      radius * 2.0 * pulse,
      ui.Paint()
        ..color = const ui.Color(0x20FFD740)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
    );

    // Draw diamond shape
    final path = ui.Path();
    final r = radius * pulse;

    for (int i = 0; i < 4; i++) {
      final angle = _rotationAngle + (i * pi / 2);
      final dx = cos(angle) * r;
      final dy = sin(angle) * r;
      if (i == 0) {
        path.moveTo(center.dx + dx, center.dy + dy);
      } else {
        path.lineTo(center.dx + dx, center.dy + dy);
      }
    }
    path.close();

    // Fragment body
    canvas.drawPath(path, ui.Paint()..color = const ui.Color(0xFFFFD740));

    // Inner bright core
    canvas.drawCircle(
      center,
      radius * 0.35,
      ui.Paint()..color = const ui.Color(0xFFFFEA00),
    );
  }
}
