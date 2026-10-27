import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game_config.dart';
import '../afterimage_game.dart';

/// A ghost that replays historical player movement.
class GhostComponent extends PositionComponent
    with HasGameReference<AfterimageGame>, CollisionCallbacks {
  final int ghostIndex;
  final int chainIndex;
  final ui.Color color;
  final double intervalStartTime;
  final double intervalDuration;
  final double spawnGameTime;
  final double? delay;

  final List<Vector2> _trail = [];
  static const int _maxTrailLength = 6;
  double _pulsePhase = 0.0;
  bool _active = true;
  bool hasSpawned = false;
  bool isInNearMissZone = false;
  double _activeTime = 0.0;
  double _opacity = 1.0;
  double _materializationTimer = GameConfig.ghostSpawnGraceDuration;

  GhostComponent({
    required this.ghostIndex,
    required this.color,
    this.chainIndex = 0,
    this.intervalStartTime = 0.0,
    this.intervalDuration = 6.0,
    this.spawnGameTime = 0.0,
    this.delay,
  });

  bool get isActive => _active;
  double get activeTime => _activeTime;
  bool get isMaterializing => _materializationTimer > 0;
  double get materializationTimer => _materializationTimer;
  double get targetHistoryTime {
    if (delay != null) {
      final currentTime =
          isMounted ? game.gameTime : (spawnGameTime + _activeTime);
      return (currentTime - delay!).clamp(0.0, double.infinity);
    }
    return intervalStartTime + _activeTime;
  }
  bool get isExpired => _activeTime >= intervalDuration;
  double get opacity => _opacity;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(GameConfig.ghostRadius * 2);
    anchor = Anchor.center;
    add(
      CircleHitbox(
        radius: GameConfig.ghostHitboxRadius,
        position: Vector2.all(GameConfig.ghostRadius),
        anchor: Anchor.center,
      ),
    );
  }

  void updateGhostPosition(Vector2 newPosition) {
    if (!_active) return;

    if (!hasSpawned) {
      hasSpawned = true;
      position = newPosition;
      _trail.clear();
      return;
    }

    _trail.insert(0, position.clone());
    if (_trail.length > _maxTrailLength) {
      _trail.removeLast();
    }

    position = newPosition;
  }

  void advanceTime(double dt) {
    if (!_active || !hasSpawned) return;
    _activeTime += dt;
    if (_materializationTimer > 0) {
      _materializationTimer -= dt;
    }
    // Fade out smoothly in the last 0.8 seconds before expiration
    const fadeDuration = 0.8;
    if (_activeTime >= intervalDuration - fadeDuration) {
      final remaining = intervalDuration - _activeTime;
      _opacity = (remaining / fadeDuration).clamp(0.0, 1.0);
    } else {
      _opacity = 1.0;
    }
  }

  void deactivate() {
    _active = false;
    hasSpawned = false;
  }

  void resetTrail() {
    _trail.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulsePhase += dt * (2.4 + chainIndex * 0.4);
  }

  @override
  void render(ui.Canvas canvas) {
    if (!_active || !hasSpawned || _opacity <= 0.01) return;

    final center = ui.Offset(GameConfig.ghostRadius, GameConfig.ghostRadius);
    final radius = GameConfig.ghostRadius;

    // Draw trail
    for (int i = 1; i < _trail.length; i++) {
      final alpha = ((1.0 - i / _trail.length) * 40 * _opacity).toInt();
      final trailRadius = radius * (1.0 - i / _trail.length) * 0.5;
      final offset = _trail[i] - position;
      canvas.drawCircle(
        ui.Offset(center.dx + offset.x, center.dy + offset.y),
        trailRadius,
        ui.Paint()..color = color.withAlpha(alpha),
      );
    }

    // Materialization warning ring while non-lethal
    if (isMaterializing) {
      final progress = (1.0 -
              (_materializationTimer / GameConfig.ghostSpawnGraceDuration))
          .clamp(0.0, 1.0);
      final ringRadius = radius * (1.2 + 0.8 * progress);
      final ringAlpha = (180 * (1.0 - progress) * _opacity).toInt();
      canvas.drawCircle(
        center,
        ringRadius,
        ui.Paint()
          ..color = color.withAlpha(ringAlpha)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Ghost glow - extra intensity during near-miss
    final pulse = 0.7 + 0.3 * sin(_pulsePhase);
    final glowAlpha = isInNearMissZone ? 35 : (isMaterializing ? 25 : 15);
    final glowScale = isInNearMissZone ? 1.8 : (isMaterializing ? 1.7 : 1.5);
    canvas.drawCircle(
      center,
      radius * glowScale * pulse,
      ui.Paint()
        ..color = color.withAlpha((glowAlpha * _opacity).toInt())
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );

    // Ghost body - translucent
    canvas.drawCircle(
      center,
      radius,
      ui.Paint()..color = color.withAlpha((120 * _opacity).toInt()),
    );

    // Inner shimmer
    canvas.drawCircle(
      center,
      radius * 0.6,
      ui.Paint()..color = color.withAlpha((60 * _opacity).toInt()),
    );

    // Core dot
    canvas.drawCircle(
      center,
      radius * 0.25,
      ui.Paint()..color = ui.Color.fromARGB((128 * _opacity).toInt(), 255, 255, 255),
    );
  }
}
