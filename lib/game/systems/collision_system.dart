import 'package:flame/components.dart';
import '../afterimage_game.dart';
import '../components/energy_fragment.dart';
import '../game_config.dart';

/// Handles all collision detection between game entities.
class CollisionSystem extends Component with HasGameReference<AfterimageGame> {
  bool _gameOverProcessed = false;

  void checkCollisions() {
    if (_gameOverProcessed) return;

    final player = game.player;
    if (player == null || player.isInvulnerable) return;

    final playerPos = player.position;

    // Check ghost collisions
    for (final ghost in game.ghosts) {
      if (!ghost.isActive || !ghost.hasSpawned || ghost.isMaterializing) {
        continue;
      }
      final dist = playerPos.distanceTo(ghost.position);
      if (dist < GameConfig.playerHitboxRadius + GameConfig.ghostHitboxRadius) {
        _triggerGameOver();
        return;
      }
      // Near miss check: awarded once per encounter
      if (dist < GameConfig.nearMissRadius &&
          dist >=
              GameConfig.playerHitboxRadius + GameConfig.ghostHitboxRadius) {
        if (!ghost.isInNearMissZone) {
          ghost.isInNearMissZone = true;
          game.scoringSystem.addNearMiss();
          game.particleSystem.spawnBurst(playerPos, player.color, count: 4);
        }
      } else if (dist >= GameConfig.nearMissRadius) {
        ghost.isInNearMissZone = false;
      }
    }

    // Check hazard collisions
    for (final hazard in game.hazards) {
      final dist = playerPos.distanceTo(hazard.position);
      if (dist < GameConfig.playerHitboxRadius + GameConfig.mineHitboxRadius) {
        _triggerGameOver();
        return;
      }
    }

    // Check fragment collisions safely backwards to avoid concurrent modification
    for (int i = game.fragments.length - 1; i >= 0; i--) {
      final fragment = game.fragments[i];
      if (fragment.isCollected) continue;
      final dist = playerPos.distanceTo(fragment.position);
      if (dist <
          GameConfig.playerHitboxRadius + GameConfig.fragmentHitboxRadius) {
        _collectFragment(fragment);
      }
    }
  }

  void _collectFragment(EnergyFragment fragment) {
    fragment.collect();
    game.scoringSystem.collectFragment();
    game.particleSystem.spawnCollectEffect(fragment.position);
    game.audioService.playCollect();
    game.remove(fragment);
    game.fragments.remove(fragment);
  }

  void _triggerGameOver() {
    if (_gameOverProcessed) return;
    _gameOverProcessed = true;
    game.particleSystem.spawnDeathEffect(game.player!.position);
    game.audioService.playExplosion();
    game.onGameOver();
  }

  void reset() {
    _gameOverProcessed = false;
  }
}
