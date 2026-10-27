import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import '../afterimage_game.dart';
import '../game_config.dart';

/// Lightweight particle for collection/death effects.
class GameParticle {
  Vector2 position;
  Vector2 velocity;
  double life;
  double maxLife;
  ui.Color color;
  double radius;

  GameParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.color,
    this.radius = 3.0,
  }) : maxLife = life;

  bool get isDead => life <= 0;

  void update(double dt) {
    life -= dt;
    position += velocity * dt;
    velocity *= 0.95;
  }

  void render(ui.Canvas canvas) {
    if (isDead) return;
    final alpha = (life / maxLife * 255).toInt().clamp(0, 255);
    final r = radius * (life / maxLife);
    canvas.drawCircle(
      ui.Offset(position.x, position.y),
      r,
      ui.Paint()..color = color.withAlpha(alpha),
    );
  }
}

/// Manages lightweight particles for visual effects.
class ParticleSystem extends Component with HasGameReference<AfterimageGame> {
  final List<GameParticle> _particles = [];
  final Random _rng = Random();

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.isDead);
  }

  @override
  void render(ui.Canvas canvas) {
    for (final p in _particles) {
      p.render(canvas);
    }
  }

  void spawnBurst(Vector2 center, ui.Color color, {int count = 12}) {
    if (_particles.length > GameConfig.maxParticles) return;

    final toSpawn = min(count, GameConfig.maxParticles - _particles.length);
    for (int i = 0; i < toSpawn; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 40 + _rng.nextDouble() * 120;
      _particles.add(
        GameParticle(
          position: center.clone(),
          velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
          life: 0.4 + _rng.nextDouble() * 0.8,
          color: color,
          radius: 2 + _rng.nextDouble() * 3,
        ),
      );
    }
  }

  void spawnCollectEffect(Vector2 center) {
    spawnBurst(center, const ui.Color(0xFFFFD740), count: 8);
  }

  void spawnDeathEffect(Vector2 center) {
    spawnBurst(center, const ui.Color(0xFFFF1744), count: 16);
    spawnBurst(center, const ui.Color(0xFFFFFFFF), count: 6);
  }

  void clear() {
    _particles.clear();
  }
}
