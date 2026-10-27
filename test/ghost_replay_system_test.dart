import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:afterimage/game/systems/ghost_replay_system.dart';
import 'package:afterimage/game/components/ghost_component.dart';
import 'package:afterimage/game/game_config.dart';

void main() {
  late GhostReplaySystem system;

  setUp(() {
    system = GhostReplaySystem();
  });

  group('Position Recording', () {
    test('records positions', () {
      system.recordPosition(0.0, Vector2(100, 200));
      system.recordPosition(0.1, Vector2(110, 210));
      expect(system.sampleCount, 2);
    });

    test('skips samples below record interval', () {
      system.recordPosition(0.0, Vector2(100, 200));
      system.recordPosition(0.01, Vector2(101, 201)); // Too soon
      expect(system.sampleCount, 1);
    });

    test('resets correctly', () {
      system.recordPosition(0.0, Vector2(100, 200));
      system.recordPosition(0.1, Vector2(110, 210));
      system.reset();
      expect(system.sampleCount, 0);
    });
  });

  group('Ghost Position Interpolation', () {
    test('returns null when no history', () {
      final pos = system.getGhostPosition(5.0, 3.0);
      expect(pos, isNull);
    });

    test('returns null when target time is before earliest sample', () {
      system.recordPosition(2.0, Vector2(100, 100));
      // Target = 3.0 - 6.0 = -3.0, before earliest
      final pos = system.getGhostPosition(3.0, 6.0);
      expect(pos, isNull);
    });

    test('returns exact position at recorded timestamp', () {
      system.recordPosition(0.0, Vector2(100, 200));
      system.recordPosition(1.0, Vector2(200, 300));
      system.recordPosition(2.0, Vector2(300, 400));

      // Ghost with 2s delay at time 2.0 → target time 0.0
      final pos = system.getGhostPosition(2.0, 2.0);
      expect(pos, isNotNull);
      expect(pos!.x, closeTo(100.0, 0.01));
      expect(pos.y, closeTo(200.0, 0.01));
    });

    test('interpolates between samples', () {
      system.recordPosition(0.0, Vector2(0, 0));
      system.recordPosition(1.0, Vector2(100, 200));

      // Ghost at target time 0.5 → halfway
      final pos = system.getGhostPosition(6.5, 6.0);
      expect(pos, isNotNull);
      expect(pos!.x, closeTo(50.0, 0.01));
      expect(pos.y, closeTo(100.0, 0.01));
    });

    test('returns last position when target after last sample', () {
      system.recordPosition(0.0, Vector2(10, 20));
      system.recordPosition(0.5, Vector2(50, 60));

      // Ghost with 0.1 delay at time 1.0 → target 0.9 > 0.5 (last)
      final pos = system.getGhostPosition(1.0, 0.1);
      expect(pos, isNotNull);
      expect(pos!.x, closeTo(50.0, 0.01));
      expect(pos.y, closeTo(60.0, 0.01));
    });

    test('ghost reproduces player path with correct delay', () {
      // Simulate player moving right at constant speed
      for (int i = 0; i <= 120; i++) {
        final t = i * 0.05; // 20 samples/sec
        system.recordPosition(t, Vector2(t * 100, 200));
      }

      // At game time 6.0, ghost with 6s delay → target 0.0
      final pos0 = system.getGhostPosition(6.0, 6.0);
      expect(pos0, isNotNull);
      expect(pos0!.x, closeTo(0.0, 5.0));

      // At game time 7.0, ghost with 6s delay → target 1.0
      final pos1 = system.getGhostPosition(7.0, 6.0);
      expect(pos1, isNotNull);
      expect(pos1!.x, closeTo(100.0, 5.0));

      // At game time 8.0, ghost with 6s delay → target 2.0
      final pos2 = system.getGhostPosition(8.0, 6.0);
      expect(pos2, isNotNull);
      expect(pos2!.x, closeTo(200.0, 5.0));
    });
  });

  group('Ghost Delay Calculation', () {
    test('first ghost has correct delay', () {
      expect(system.getGhostDelay(0), 6.0);
    });

    test('second ghost has 12s delay', () {
      expect(system.getGhostDelay(1), 12.0);
    });

    test('third ghost has 18s delay', () {
      expect(system.getGhostDelay(2), 18.0);
    });
  });

  group('History for Delay', () {
    test('no history returns false', () {
      expect(system.hasHistoryForDelay(5.0, 3.0), false);
    });

    test('returns true when enough history', () {
      system.recordPosition(0.0, Vector2.zero());
      expect(system.hasHistoryForDelay(5.0, 3.0), true);
    });
  });

  group('Direct Timestamp Query (getPositionAtTime)', () {
    test('returns null when no history or before start', () {
      expect(system.getPositionAtTime(5.0), isNull);
      system.recordPosition(5.0, Vector2(100, 100));
      expect(system.getPositionAtTime(4.0), isNull);
    });

    test('interpolates correctly at specific timestamp', () {
      system.recordPosition(0.0, Vector2(0, 0));
      system.recordPosition(10.0, Vector2(100, 200));

      final mid = system.getPositionAtTime(5.0);
      expect(mid, isNotNull);
      expect(mid!.x, closeTo(50.0, 0.01));
      expect(mid.y, closeTo(100.0, 0.01));
    });
  });

  group('Interval Ghost Lifecycle & Expiration', () {
    test('ghost starts with full opacity and unexpired', () {
      final ghost = GhostComponent(
        ghostIndex: 1,
        color: const ui.Color(0xFF9C27B0),
        intervalStartTime: 5.0,
        intervalDuration: 6.0,
        spawnGameTime: 10.0,
      );

      ghost.updateGhostPosition(Vector2(50, 50));
      expect(ghost.hasSpawned, true);
      expect(ghost.targetHistoryTime, 5.0);
      expect(ghost.isExpired, false);
      expect(ghost.opacity, 1.0);
    });

    test('ghost advances time and updates target history time', () {
      final ghost = GhostComponent(
        ghostIndex: 1,
        color: const ui.Color(0xFF9C27B0),
        intervalStartTime: 5.0,
        intervalDuration: 6.0,
        spawnGameTime: 10.0,
      );

      ghost.updateGhostPosition(Vector2(50, 50));
      ghost.advanceTime(2.5);

      expect(ghost.activeTime, 2.5);
      expect(ghost.targetHistoryTime, closeTo(7.5, 0.01));
      expect(ghost.isExpired, false);
      expect(ghost.opacity, 1.0);
    });

    test('ghost fades out near end of duration and expires', () {
      final ghost = GhostComponent(
        ghostIndex: 1,
        color: const ui.Color(0xFF9C27B0),
        intervalStartTime: 5.0,
        intervalDuration: 6.0,
        spawnGameTime: 10.0,
      );

      ghost.updateGhostPosition(Vector2(50, 50));

      // Advance into fade window (fade window is last 0.8s, so at 5.6s remaining is 0.4s -> 50% opacity)
      ghost.advanceTime(5.6);
      expect(ghost.opacity, closeTo(0.5, 0.05));
      expect(ghost.isExpired, false);

      // Advance past duration -> expired
      ghost.advanceTime(0.5); // total 6.1s >= 6.0s
      expect(ghost.isExpired, true);
      expect(ghost.opacity, 0.0);
    });
  });

  group('Multi-Version Self-Chasing Replay', () {
    test('consecutive versions replicate path with exact spacing delay (Ghost k chases Ghost k-1)', () {
      // Record player moving along a path
      for (int i = 0; i <= 200; i++) {
        final t = i * 0.05; // 20 samples/sec for 10 seconds
        system.recordPosition(t, Vector2(t * 100, 200));
      }

      const gameTime = 10.0;
      final d0 = system.getChasingVersionDelay(0); // Lead ghost
      final d1 = system.getChasingVersionDelay(1); // Second ghost
      final d2 = system.getChasingVersionDelay(2); // Third ghost

      final pos0 = system.getGhostPosition(gameTime, d0);
      final pos1 = system.getGhostPosition(gameTime, d1);
      final pos2 = system.getGhostPosition(gameTime, d2);

      expect(pos0, isNotNull);
      expect(pos1, isNotNull);
      expect(pos2, isNotNull);

      // Ghost 0 is ahead of Ghost 1, and Ghost 1 is ahead of Ghost 2
      expect(pos0!.x, greaterThan(pos1!.x));
      expect(pos1.x, greaterThan(pos2!.x));

      // Ghost 1 position matches Ghost 0 position from (d1 - d0) seconds earlier
      final pos0Earlier = system.getGhostPosition(gameTime - (d1 - d0), d0);
      expect(pos1.x, closeTo(pos0Earlier!.x, 0.01));
      expect(pos1.y, closeTo(pos0Earlier.y, 0.01));

      // Ghost 2 position matches Ghost 1 position from (d2 - d1) seconds earlier
      final pos1Earlier = system.getGhostPosition(gameTime - (d2 - d1), d1);
      expect(pos2.x, closeTo(pos1Earlier!.x, 0.01));
      expect(pos2.y, closeTo(pos1Earlier.y, 0.01));
    });

    test('ghost component supports direct delay and tracks target history time', () {
      final ghost = GhostComponent(
        ghostIndex: 0,
        chainIndex: 1,
        color: const ui.Color(0xFFFF007F),
        delay: 4.5,
        intervalDuration: 10.0,
        spawnGameTime: 8.0,
      );

      // At spawn, activeTime is 0 -> target history time is 8.0 - 4.5 = 3.5
      expect(ghost.targetHistoryTime, closeTo(3.5, 0.001));

      // After spawning and 2 seconds of active time -> target history time is (8.0 + 2.0) - 4.5 = 5.5
      ghost.updateGhostPosition(Vector2(100, 100));
      ghost.advanceTime(2.0);
      expect(ghost.targetHistoryTime, closeTo(5.5, 0.001));
      expect(ghost.chainIndex, 1);
    });

    test('ghost has non-lethal materialization grace period on spawn', () {
      final ghost = GhostComponent(
        ghostIndex: 0,
        chainIndex: 0,
        color: const ui.Color(0xFF00E5FF),
        delay: 3.0,
      );

      ghost.updateGhostPosition(Vector2(50, 50));
      expect(ghost.isMaterializing, true);
      expect(ghost.materializationTimer, GameConfig.ghostSpawnGraceDuration);

      // Advance halfway through grace period
      ghost.advanceTime(GameConfig.ghostSpawnGraceDuration / 2);
      expect(ghost.isMaterializing, true);

      // Advance past grace period
      ghost.advanceTime(GameConfig.ghostSpawnGraceDuration / 2 + 0.05);
      expect(ghost.isMaterializing, false);
    });

    test('hasHistoryForDelay returns false when target time is negative', () {
      system.recordPosition(0.0, Vector2(10, 10));
      system.recordPosition(1.0, Vector2(20, 20));

      // currentTime (0.5) < delay (1.0) -> targetTime -0.5 < 0
      expect(system.hasHistoryForDelay(0.5, 1.0), false);
      expect(system.hasHistoryForDelay(1.0, 1.0), true);
    });

    test('prompt multi-ghost spawn readiness without artificial delay gaps', () {
      // Simulate 15 seconds of player movement
      for (int i = 0; i <= 300; i++) {
        final t = i * 0.05;
        system.recordPosition(t, Vector2(t * 10, t * 10));
      }

      // Check all 6 chain indices delays
      for (int i = 0; i < GameConfig.maxGhosts; i++) {
        final delay = system.getChasingVersionDelay(i);
        // Once gameTime reaches delay, hasHistory must be immediately true
        expect(system.hasHistoryForDelay(delay, delay), true);
        // And position must be non-null and sampleable
        final pos = system.getPositionAtTime(delay - delay);
        expect(pos, isNotNull);
      }
    });
  });
}
