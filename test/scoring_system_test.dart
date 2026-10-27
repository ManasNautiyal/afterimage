import 'package:flutter_test/flutter_test.dart';
import 'package:afterimage/game/systems/scoring_system.dart';
import 'package:afterimage/game/game_config.dart';

void main() {
  late ScoringSystem system;

  setUp(() {
    system = ScoringSystem();
  });

  group('Score Calculation', () {
    test('starts at 0', () {
      expect(system.score, 0);
      expect(system.survivalTime, 0.0);
      expect(system.fragmentsCollected, 0);
    });

    test('survival time contributes to score', () {
      system.update(10.0); // 10 seconds
      final expectedTimeScore = (10.0 * GameConfig.scorePerSecond).floor();
      expect(system.score, expectedTimeScore);
    });

    test('fragments contribute to score', () {
      system.collectFragment();
      system.collectFragment();
      expect(system.fragmentsCollected, 2);
      expect(system.score, 2 * GameConfig.scorePerFragment);
    });

    test('combined score is correct', () {
      system.update(5.0);
      system.collectFragment();
      system.addNearMiss();

      final expected =
          (5.0 * GameConfig.scorePerSecond).floor() +
          GameConfig.scorePerFragment +
          GameConfig.nearMissBonus;
      expect(system.score, expected);
    });
  });

  group('Currency', () {
    test('currency earned includes fragments and survival', () {
      system.update(10.0);
      system.collectFragment();
      system.collectFragment();
      // 2 fragments + (10 * 0.5) = 7
      expect(system.currencyEarned, 7);
    });
  });

  group('Freeze / Unfreeze', () {
    test('freezing stops score accumulation', () {
      system.update(5.0);
      system.freeze();
      final scoreBeforeFreeze = system.score;
      system.update(10.0); // Should be ignored
      expect(system.score, scoreBeforeFreeze);
    });

    test('freezing stops fragment collection', () {
      system.freeze();
      system.collectFragment(); // Should be ignored
      expect(system.fragmentsCollected, 0);
    });

    test('unfreezing resumes scoring', () {
      system.freeze();
      system.unfreeze();
      system.update(5.0);
      expect(system.survivalTime, closeTo(5.0, 0.01));
    });

    test('game over triggers only once via freeze', () {
      system.update(5.0);
      system.freeze();
      expect(system.isFrozen, true);
      // Second freeze is idempotent
      system.freeze();
      expect(system.isFrozen, true);
    });
  });

  group('Reset', () {
    test('resets all values', () {
      system.update(10.0);
      system.collectFragment();
      system.addNearMiss();
      system.freeze();
      system.reset();

      expect(system.score, 0);
      expect(system.survivalTime, 0.0);
      expect(system.fragmentsCollected, 0);
      expect(system.nearMisses, 0);
      expect(system.isFrozen, false);
    });
  });
}
