import 'package:flutter_test/flutter_test.dart';
import 'package:afterimage/game/systems/difficulty_system.dart';
import 'package:afterimage/game/game_config.dart';

void main() {
  late DifficultySystem system;

  setUp(() {
    system = DifficultySystem();
  });

  group('Difficulty Progression', () {
    test('starts at 0', () {
      expect(system.difficulty, 0.0);
      expect(system.elapsedTime, 0.0);
    });

    test('stays 0 before ramp start time', () {
      system.update(GameConfig.difficultyRampStartTime - 1);
      expect(system.difficulty, 0.0);
    });

    test('increases after ramp start time', () {
      system.update(GameConfig.difficultyRampStartTime + 10);
      expect(system.difficulty, greaterThan(0.0));
    });

    test('never exceeds 1.0', () {
      // Update with a very long time
      system.update(
        GameConfig.difficultyRampStartTime +
            GameConfig.difficultyRampDuration +
            1000,
      );
      expect(system.difficulty, 1.0);
    });

    test('resets correctly', () {
      system.update(60);
      system.reset();
      expect(system.difficulty, 0.0);
      expect(system.elapsedTime, 0.0);
    });
  });

  group('Speed Multiplier', () {
    test('starts at 1.0', () {
      expect(system.speedMultiplier, 1.0);
    });

    test('increases with difficulty', () {
      system.update(GameConfig.difficultyRampStartTime + 60);
      expect(system.speedMultiplier, greaterThan(1.0));
    });

    test('never exceeds max speed multiplier', () {
      system.update(
        GameConfig.difficultyRampStartTime +
            GameConfig.difficultyRampDuration +
            1000,
      );
      expect(
        system.speedMultiplier,
        closeTo(GameConfig.maxSpeedMultiplier, 0.01),
      );
    });
  });

  group('Hazard Spawn Interval', () {
    test('starts at max interval (slow spawning)', () {
      expect(
        system.hazardSpawnInterval,
        closeTo(GameConfig.maxSpawnInterval, 0.01),
      );
    });

    test('decreases with difficulty (faster spawning)', () {
      system.update(GameConfig.difficultyRampStartTime + 60);
      expect(system.hazardSpawnInterval, lessThan(GameConfig.maxSpawnInterval));
    });

    test('never goes below min interval', () {
      system.update(
        GameConfig.difficultyRampStartTime +
            GameConfig.difficultyRampDuration +
            1000,
      );
      expect(
        system.hazardSpawnInterval,
        closeTo(GameConfig.minSpawnInterval, 0.01),
      );
    });
  });

  group('Ghost Count', () {
    test('no ghosts before first ghost delay', () {
      system.update(GameConfig.firstGhostDelay - 1);
      expect(system.targetGhostCount, 0);
    });

    test('multiple versions (at least 2) after first ghost delay', () {
      system.update(GameConfig.firstGhostDelay + 0.1);
      expect(system.targetGhostCount, GameConfig.minConcurrentGhosts);
      expect(system.targetGhostCount, greaterThanOrEqualTo(2));
    });

    test('3 ghosts after subsequent interval', () {
      system.update(
        GameConfig.firstGhostDelay + GameConfig.ghostSpawnInterval + 0.1,
      );
      expect(system.targetGhostCount, 3);
    });

    test('ghost count scales progressively from 2 to 6 over survival intervals', () {
      // 0s: 0 ghosts
      expect(system.targetGhostCount, 0);

      // 6s (first ghost delay): 2 ghosts
      system.update(GameConfig.firstGhostDelay + 0.1);
      expect(system.targetGhostCount, 2);

      // 12s (+1 interval): 3 ghosts
      system.update(GameConfig.ghostSpawnInterval);
      expect(system.targetGhostCount, 3);

      // 18s (+2 intervals): 4 ghosts
      system.update(GameConfig.ghostSpawnInterval);
      expect(system.targetGhostCount, 4);

      // 24s (+3 intervals): 5 ghosts
      system.update(GameConfig.ghostSpawnInterval);
      expect(system.targetGhostCount, 5);

      // 30s (+4 intervals): 6 ghosts
      system.update(GameConfig.ghostSpawnInterval);
      expect(system.targetGhostCount, 6);
    });

    test('max ghosts capped', () {
      system.update(300); // Very long time
      expect(system.targetGhostCount, GameConfig.maxGhosts);
    });
  });

  group('Multi-Version Self-Chasing & Mathematical Playability', () {
    test('lead ghost delay provides safe human reaction horizon at all difficulties', () {
      // At start (difficulty 0.0)
      expect(system.leadGhostDelay, closeTo(GameConfig.baseLeadGhostDelay, 0.01));
      // Reversal head-on collision horizon must be >= 1.0s
      expect(system.leadGhostDelay / 2, greaterThanOrEqualTo(1.0));

      // At max difficulty (difficulty 1.0)
      system.update(
        GameConfig.difficultyRampStartTime + GameConfig.difficultyRampDuration,
      );
      expect(system.leadGhostDelay, closeTo(GameConfig.minLeadGhostDelay, 0.01));
      expect(system.leadGhostDelay / 2, greaterThanOrEqualTo(1.0));
    });

    test('ghost spacing provides mathematically traversable gaps between versions', () {
      // At start
      expect(system.ghostSpacing, closeTo(GameConfig.baseGhostSpacing, 0.01));
      // Net crossing window: spacing - (2 * hitbox / playerSpeed) >= 1.4s
      const crossingTime = (GameConfig.playerHitboxRadius + GameConfig.ghostHitboxRadius) * 2 / GameConfig.playerSpeed;
      expect(system.ghostSpacing - crossingTime, greaterThan(1.4));

      // At max difficulty
      system.update(
        GameConfig.difficultyRampStartTime + GameConfig.difficultyRampDuration,
      );
      expect(system.ghostSpacing, closeTo(GameConfig.minGhostSpacing, 0.01));
      expect(system.ghostSpacing - crossingTime, greaterThan(1.4));
    });

    test('delays strictly increase along the self-chasing chain', () {
      final d0 = system.getGhostDelayForIndex(0);
      final d1 = system.getGhostDelayForIndex(1);
      final d2 = system.getGhostDelayForIndex(2);
      final d3 = system.getGhostDelayForIndex(3);

      expect(d0, lessThan(d1));
      expect(d1, lessThan(d2));
      expect(d2, lessThan(d3));

      // Adjacent differences match ghostSpacing
      expect(d1 - d0, closeTo(system.ghostSpacing, 0.001));
      expect(d2 - d1, closeTo(system.ghostSpacing, 0.001));
      expect(d3 - d2, closeTo(system.ghostSpacing, 0.001));
    });
  });

  group('Ghost Interval and Duration Scaling', () {
    test('ghost spawn interval starts at default and scales down with difficulty', () {
      expect(
        system.ghostSpawnInterval,
        closeTo(GameConfig.ghostSpawnInterval, 0.01),
      );

      // Advance to full difficulty
      system.update(
        GameConfig.difficultyRampStartTime + GameConfig.difficultyRampDuration,
      );
      expect(
        system.ghostSpawnInterval,
        closeTo(GameConfig.minGhostSpawnInterval, 0.01),
      );
    });

    test('ghost duration starts at base and increases with difficulty', () {
      expect(
        system.ghostDuration,
        closeTo(GameConfig.baseGhostDuration, 0.01),
      );

      // Advance to full difficulty
      system.update(
        GameConfig.difficultyRampStartTime + GameConfig.difficultyRampDuration,
      );
      expect(
        system.ghostDuration,
        closeTo(GameConfig.maxGhostDuration, 0.01),
      );
    });

    test('max concurrent ghosts scales within configured bounds', () {
      expect(system.maxConcurrentGhosts, GameConfig.minConcurrentGhosts);

      // Advance to full difficulty
      system.update(
        GameConfig.difficultyRampStartTime + GameConfig.difficultyRampDuration,
      );
      expect(system.maxConcurrentGhosts, GameConfig.maxConcurrentGhosts);
    });
  });

  group('Max Mines', () {
    test('starts at initial count', () {
      expect(system.maxMines, GameConfig.initialMineCount);
    });

    test('increases with difficulty', () {
      system.update(
        GameConfig.difficultyRampStartTime + GameConfig.difficultyRampDuration,
      );
      expect(system.maxMines, GameConfig.maxMineCount);
    });
  });
}

