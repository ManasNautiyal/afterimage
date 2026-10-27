import '../game_config.dart';

/// Scoring system. Score = survival time contribution + fragment bonuses.
class ScoringSystem {
  double _survivalTime = 0.0;
  int _fragmentsCollected = 0;
  int _nearMisses = 0;
  bool _frozen = false;

  double get survivalTime => _survivalTime;
  int get fragmentsCollected => _fragmentsCollected;
  int get nearMisses => _nearMisses;

  /// Current score. Always non-negative.
  int get score {
    final timeScore = (_survivalTime * GameConfig.scorePerSecond).floor();
    final fragScore = _fragmentsCollected * GameConfig.scorePerFragment;
    final nearScore = _nearMisses * GameConfig.nearMissBonus;
    return timeScore + fragScore + nearScore;
  }

  /// Currency earned this run.
  int get currencyEarned {
    return _fragmentsCollected +
        (_survivalTime * 0.5).floor(); // 1 currency per fragment + 0.5/sec
  }

  /// Update survival time. No-op if frozen (game over / paused).
  void update(double dt) {
    if (_frozen) return;
    _survivalTime += dt;
  }

  void collectFragment() {
    if (_frozen) return;
    _fragmentsCollected++;
  }

  void addNearMiss() {
    if (_frozen) return;
    _nearMisses++;
  }

  /// Freeze scoring (game over).
  void freeze() {
    _frozen = true;
  }

  /// Unfreeze scoring (resume from pause).
  void unfreeze() {
    _frozen = false;
  }

  bool get isFrozen => _frozen;

  void reset() {
    _survivalTime = 0.0;
    _fragmentsCollected = 0;
    _nearMisses = 0;
    _frozen = false;
  }
}
