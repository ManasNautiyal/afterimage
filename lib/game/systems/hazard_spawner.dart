import 'dart:math';
import 'package:flame/components.dart';
import '../afterimage_game.dart';
import '../components/hazard_component.dart';
import '../game_config.dart';

/// Spawns hazards based on difficulty and manages their lifecycle.
class HazardSpawner extends Component with HasGameReference<AfterimageGame> {
  final Random _rng = Random();
  double _timeSinceLastSpawn = 0.0;
  bool _active = false;

  void activate() => _active = true;
  void deactivate() => _active = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    _timeSinceLastSpawn += dt;

    final interval = game.difficultySystem.hazardSpawnInterval;
    final maxMines = game.difficultySystem.maxMines;

    if (_timeSinceLastSpawn >= interval) {
      _timeSinceLastSpawn = 0;
      _trySpawnHazard(maxMines);
    }
  }

  void _trySpawnHazard(int maxMines) {
    final currentMines = game.hazards.length;
    if (currentMines >= maxMines) return;

    final arena = game.arena;
    final player = game.player;
    if (arena == null || player == null) return;

    final difficulty = game.difficultySystem.difficulty;
    HazardType type;
    if (difficulty < 0.3 || _rng.nextDouble() > 0.3) {
      type = HazardType.mine;
    } else {
      type = HazardType.movingWall;
    }

    final hazard = HazardComponent(
      type: type,
      moveSpeed: 60 * game.difficultySystem.speedMultiplier,
    );

    final pos = arena.randomPositionAwayFrom(
      _rng,
      player.position,
      GameConfig.minSpawnDistanceFromPlayer,
    );
    hazard.position = pos;

    if (type == HazardType.movingWall) {
      final endPos = arena.randomPosition(_rng, margin: 30);
      hazard.setMoveEndpoints(pos, endPos);
    }

    game.addHazard(hazard);
  }

  void reset() {
    _timeSinceLastSpawn = 0.0;
    _active = false;
  }
}
