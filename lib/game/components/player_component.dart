import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game_config.dart';
import '../afterimage_game.dart';

/// The player character: a glowing circle with trail effect.
class PlayerComponent extends PositionComponent
    with HasGameReference<AfterimageGame>, CollisionCallbacks {
  final ui.Color color;
  Vector2 velocity = Vector2.zero();
  final List<Vector2> _trail = [];
  static const int _maxTrailLength = 8;
  bool isInvulnerable = false;
  double _invulnerableTimer = 0.0;
  double _pulsePhase = 0.0;

  PlayerComponent({required this.color});

  @override
  Future<void> onLoad() async {
    size = Vector2.all(GameConfig.playerRadius * 2);
    anchor = Anchor.center;
    // Hitbox is smaller than visual
    add(
      CircleHitbox(
        radius: GameConfig.playerHitboxRadius,
        position: Vector2.all(GameConfig.playerRadius),
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _pulsePhase += dt * 3;

    if (isInvulnerable) {
      _invulnerableTimer -= dt;
      if (_invulnerableTimer <= 0) {
        isInvulnerable = false;
        _invulnerableTimer = 0;
      }
    }

    // Trail recording
    _trail.insert(0, position.clone());
    if (_trail.length > _maxTrailLength) {
      _trail.removeLast();
    }
  }

  void setInvulnerable(double duration) {
    isInvulnerable = true;
    _invulnerableTimer = duration;
  }

  @override
  void render(ui.Canvas canvas) {
    final center = ui.Offset(GameConfig.playerRadius, GameConfig.playerRadius);
    final radius = GameConfig.playerRadius;

    // Draw trail
    for (int i = 1; i < _trail.length; i++) {
      final alpha = ((1.0 - i / _trail.length) * 80).toInt();
      final trailRadius = radius * (1.0 - i / _trail.length) * 0.6;
      final offset = _trail[i] - position;
      canvas.drawCircle(
        ui.Offset(center.dx + offset.x, center.dy + offset.y),
        trailRadius,
        ui.Paint()..color = color.withAlpha(alpha),
      );
    }

    // Outer glow
    final pulse = 0.8 + 0.2 * sin(_pulsePhase);
    canvas.drawCircle(
      center,
      radius * 1.6 * pulse,
      ui.Paint()
        ..color = color.withAlpha(25)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
    );

    // Inner glow
    canvas.drawCircle(
      center,
      radius * 1.2,
      ui.Paint()
        ..color = color.withAlpha(50)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );

    // Main body - flash when invulnerable
    if (isInvulnerable && ((_invulnerableTimer * 8).floor() % 2 == 0)) {
      canvas.drawCircle(
        center,
        radius,
        ui.Paint()..color = const ui.Color(0xCCFFFFFF),
      );
    } else {
      // Gradient body
      final gradient = ui.Gradient.radial(
        center,
        radius,
        [
          ui.Color.lerp(color, const ui.Color(0xFFFFFFFF), 0.4)!,
          color,
          color.withAlpha(200),
        ],
        [0.0, 0.5, 1.0],
      );
      canvas.drawCircle(center, radius, ui.Paint()..shader = gradient);
    }

    // Core highlight
    canvas.drawCircle(
      ui.Offset(center.dx - radius * 0.25, center.dy - radius * 0.25),
      radius * 0.35,
      ui.Paint()..color = const ui.Color(0x60FFFFFF),
    );
  }

  void resetTrail() {
    _trail.clear();
  }
}
