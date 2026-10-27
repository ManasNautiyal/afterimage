import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game_config.dart';
import '../afterimage_game.dart';

/// Types of hazards in the arena.
enum HazardType { mine, beam, movingWall }

/// Hazard component: static mines and moving obstacles.
class HazardComponent extends PositionComponent
    with HasGameReference<AfterimageGame>, CollisionCallbacks {
  final HazardType type;
  double _pulsePhase = 0.0;
  double _movePhase = 0.0;
  double _moveSpeed;

  // For moving hazards
  Vector2? _startPos;
  Vector2? _endPos;

  HazardComponent({this.type = HazardType.mine, double moveSpeed = 60.0})
    : _moveSpeed = moveSpeed;

  @override
  Future<void> onLoad() async {
    final radius =
        type == HazardType.mine
            ? GameConfig.mineRadius
            : GameConfig.mineRadius * 1.2;
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
    _pulsePhase = Random().nextDouble() * pi * 2;

    add(
      CircleHitbox(
        radius: GameConfig.mineHitboxRadius,
        position: Vector2.all(radius),
        anchor: Anchor.center,
      ),
    );
  }

  void setMoveEndpoints(Vector2 start, Vector2 end) {
    _startPos = start;
    _endPos = end;
    position = start.clone();
  }

  void setSpeedMultiplier(double multiplier) {
    _moveSpeed = 60.0 * multiplier;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulsePhase += dt * 3;

    if (type == HazardType.movingWall && _startPos != null && _endPos != null) {
      _movePhase += dt * _moveSpeed;
      final totalDist = _startPos!.distanceTo(_endPos!);
      if (totalDist > 0) {
        final progress = (_movePhase % (totalDist * 2)) / totalDist;
        final t = progress > 1.0 ? 2.0 - progress : progress;
        position = _startPos! + (_endPos! - _startPos!) * t;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final radius = size.x / 2;
    final center = ui.Offset(radius, radius);
    final pulse = 0.8 + 0.2 * sin(_pulsePhase);

    // Danger glow
    canvas.drawCircle(
      center,
      radius * 1.8 * pulse,
      ui.Paint()
        ..color = const ui.Color(0x18FF1744)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
    );

    // Outer ring
    canvas.drawCircle(
      center,
      radius * 1.1,
      ui.Paint()
        ..color = const ui.Color(0x60FF1744)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Main body with gradient
    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        const ui.Color(0xFFFF6D00),
        const ui.Color(0xFFFF1744),
        const ui.Color(0xFFD50000),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(center, radius, ui.Paint()..shader = gradient);

    // Core
    canvas.drawCircle(
      center,
      radius * 0.3 * pulse,
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  }
}
