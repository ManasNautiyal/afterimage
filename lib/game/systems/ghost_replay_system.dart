import 'package:flame/components.dart';
import '../game_config.dart';

/// A timestamped position sample for ghost replay.
class PositionSample {
  final double time;
  final double x;
  final double y;

  const PositionSample(this.time, this.x, this.y);

  Vector2 toVector2() => Vector2(x, y);
}

/// Records player positions and provides interpolated playback for ghosts.
class GhostReplaySystem {
  final List<PositionSample> _history = [];
  double _lastRecordTime = -1.0;
  double _gameTime = 0.0;

  List<PositionSample> get history => List.unmodifiable(_history);
  int get sampleCount => _history.length;
  double get gameTime => _gameTime;

  void recordPosition(double gameTime, Vector2 position) {
    _gameTime = gameTime;

    if (_lastRecordTime >= 0 &&
        (gameTime - _lastRecordTime) < GameConfig.recordInterval) {
      return;
    }

    _history.add(PositionSample(gameTime, position.x, position.y));
    _lastRecordTime = gameTime;

    if (_history.length > GameConfig.maxHistorySamples) {
      _history.removeAt(0);
    }
  }

  /// Get interpolated player position at a specific target history time.
  Vector2? getPositionAtTime(double targetTime) {
    if (targetTime < 0 || _history.isEmpty) return null;
    if (targetTime < _history.first.time) return null;
    if (targetTime >= _history.last.time) {
      return _history.last.toVector2();
    }

    // Binary search
    int lo = 0;
    int hi = _history.length - 1;

    while (lo < hi - 1) {
      final mid = (lo + hi) ~/ 2;
      if (_history[mid].time <= targetTime) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final a = _history[lo];
    final b = _history[hi];
    final range = b.time - a.time;

    if (range <= 0) return a.toVector2();

    final t = ((targetTime - a.time) / range).clamp(0.0, 1.0);

    return Vector2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
  }

  /// Get interpolated ghost position using delay (target = currentTime - delay).
  Vector2? getGhostPosition(double currentTime, double delay) {
    return getPositionAtTime(currentTime - delay);
  }

  bool hasHistoryForDelay(double currentTime, double delay) {
    if (_history.isEmpty) return false;
    final targetTime = currentTime - delay;
    return targetTime >= 0.0 && targetTime >= _history.first.time;
  }

  double getGhostDelay(int ghostIndex) {
    return 6.0 + ghostIndex * 6.0;
  }

  /// Calculates the delay for version at [chainIndex] in the self-chasing echo train.
  /// Ghost 0 chases player at [leadDelay].
  /// Ghost 1 chases Ghost 0 at [leadDelay + spacing].
  /// Ghost 2 chases Ghost 1 at [leadDelay + 2 * spacing], etc.
  double getChasingVersionDelay(int chainIndex, {double difficulty = 0.0}) {
    final clampedDiff = difficulty.clamp(0.0, 1.0);
    final leadDelay = GameConfig.baseLeadGhostDelay -
        clampedDiff *
            (GameConfig.baseLeadGhostDelay - GameConfig.minLeadGhostDelay);
    final spacing = GameConfig.baseGhostSpacing -
        clampedDiff *
            (GameConfig.baseGhostSpacing - GameConfig.minGhostSpacing);
    return leadDelay + chainIndex * spacing;
  }

  void reset() {
    _history.clear();
    _lastRecordTime = -1.0;
    _gameTime = 0.0;
  }
}
