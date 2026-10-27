import 'dart:math';
import '../game_config.dart';

/// Centralized difficulty system. Difficulty progresses from 0.0 to 1.0
/// based on survival time, with bounded min/max for all parameters.
class DifficultySystem {
  double _currentDifficulty = 0.0;
  double _elapsedTime = 0.0;

  double get difficulty => _currentDifficulty;
  double get elapsedTime => _elapsedTime;

  /// Update difficulty based on elapsed game time.
  void update(double dt) {
    _elapsedTime += dt;

    if (_elapsedTime < GameConfig.difficultyRampStartTime) {
      _currentDifficulty = 0.0;
    } else {
      final rampTime = _elapsedTime - GameConfig.difficultyRampStartTime;
      _currentDifficulty = min(
        1.0,
        rampTime / GameConfig.difficultyRampDuration,
      );
    }
  }

  /// Current speed multiplier for hazards, clamped to [1.0, maxSpeedMultiplier].
  double get speedMultiplier {
    return 1.0 + _currentDifficulty * (GameConfig.maxSpeedMultiplier - 1.0);
  }

  /// Current hazard spawn interval in seconds, clamped between min and max.
  double get hazardSpawnInterval {
    return GameConfig.maxSpawnInterval -
        _currentDifficulty *
            (GameConfig.maxSpawnInterval - GameConfig.minSpawnInterval);
  }

  /// Max mines allowed at current difficulty.
  int get maxMines {
    return GameConfig.initialMineCount +
        ((_currentDifficulty *
                (GameConfig.maxMineCount - GameConfig.initialMineCount))
            .round());
  }

  /// Current ghost spawn interval in seconds, ramping down with difficulty.
  double get ghostSpawnInterval {
    return GameConfig.ghostSpawnInterval -
        _currentDifficulty *
            (GameConfig.ghostSpawnInterval - GameConfig.minGhostSpawnInterval);
  }

  /// Replay lifespan of a ghost in seconds, scaling with difficulty.
  double get ghostDuration {
    return GameConfig.baseGhostDuration +
        _currentDifficulty *
            (GameConfig.maxGhostDuration - GameConfig.baseGhostDuration);
  }

  /// Max concurrent active ghosts allowed at current difficulty.
  int get maxConcurrentGhosts {
    final count = GameConfig.minConcurrentGhosts +
        ((_currentDifficulty *
                (GameConfig.maxConcurrentGhosts -
                    GameConfig.minConcurrentGhosts))
            .round());
    return count.clamp(GameConfig.minConcurrentGhosts, GameConfig.maxGhosts);
  }

  /// How many ghosts should be active at the current time.
  int get targetGhostCount {
    if (_elapsedTime < GameConfig.firstGhostDelay) return 0;
    final ghostTime = _elapsedTime - GameConfig.firstGhostDelay;
    final count = GameConfig.minConcurrentGhosts +
        (ghostTime / GameConfig.ghostSpawnInterval).floor();
    return min(count, GameConfig.maxGhosts);
  }

  /// Lead ghost delay behind player (seconds), scaling down with difficulty.
  double get leadGhostDelay {
    return GameConfig.baseLeadGhostDelay -
        _currentDifficulty *
            (GameConfig.baseLeadGhostDelay - GameConfig.minLeadGhostDelay);
  }

  /// Spacing between consecutive ghosts in the self-chasing chain (seconds).
  double get ghostSpacing {
    return GameConfig.baseGhostSpacing -
        _currentDifficulty *
            (GameConfig.baseGhostSpacing - GameConfig.minGhostSpacing);
  }

  /// Get delay for version at [chainIndex] in the self-chasing train.
  double getGhostDelayForIndex(int chainIndex) {
    return leadGhostDelay + chainIndex * ghostSpacing;
  }

  /// Reset for a new run.
  void reset() {
    _currentDifficulty = 0.0;
    _elapsedTime = 0.0;
  }
}
