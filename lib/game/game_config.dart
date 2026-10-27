/// Centralized game configuration for AFTERIMAGE.
/// Adjust these values to tune difficulty, pacing, and feel.
class GameConfig {
  GameConfig._();

  // Arena
  static const double arenaPadding = 20.0;
  static const double arenaGridSpacing = 40.0;

  // Player
  static const double playerRadius = 14.0;
  static const double playerSpeed = 220.0;
  static const double playerHitboxRadius = 11.0; // Smaller than visual
  static const double joystickDeadZone = 0.15;

  // Ghost replay
  static const double recordInterval = 0.033; // ~30 samples/sec
  static const int maxHistorySamples = 18000; // 10 min at 30 samples/sec
  static const double firstGhostDelay = 2.5; // seconds until first ghost (fast, responsive start)
  static const double ghostSpawnInterval = 2.0; // seconds between subsequent ghosts joining
  static const double minGhostSpawnInterval = 1.5; // tightest spawn interval at max difficulty
  static const double baseGhostDuration = 24.0; // Ghosts remain active to build the full chase caravan
  static const double maxGhostDuration = 40.0;
  static const int minConcurrentGhosts = 2; // At least 2 versions chase instead of just one!
  static const int maxConcurrentGhosts = 6;
  static const int maxGhosts = 6;
  static const double ghostRadius = 13.0;
  static const double ghostHitboxRadius = 10.0;
  static const double ghostTrailLength = 5; // Number of trail segments
  static const double ghostSpawnSafeRadius =
      80.0; // Min distance from player at spawn (informational)
  static const double ghostSpawnGraceDuration =
      0.8; // Grace period during materialization when ghost is non-lethal

  // Multi-version self-chasing parameters (mathematically tuned for fair playability)
  static const double baseLeadGhostDelay = 2.4; // Lead ghost follows 2.4s behind player
  static const double minLeadGhostDelay = 2.0; // Tightest lead delay at max difficulty (reaction time >= 1.0s)
  static const double baseGhostSpacing = 2.0; // 2.0s spacing between adjacent versions (crossing window > 1.8s)
  static const double minGhostSpacing = 1.6; // Tightest spacing at max difficulty (crossing window > 1.4s)

  // Energy fragments
  static const double fragmentRadius = 8.0;
  static const double fragmentHitboxRadius = 12.0; // Generous pickup
  static const int initialFragmentCount = 5;
  static const int maxFragments = 8;
  static const double fragmentRespawnDelay = 2.0;

  // Hazards
  static const double mineRadius = 10.0;
  static const double mineHitboxRadius = 9.0;
  static const int initialMineCount = 2;
  static const double minSpawnDistanceFromPlayer = 100.0;

  // Scoring
  static const double scorePerSecond = 10.0;
  static const int scorePerFragment = 25;
  static const int nearMissBonus = 5;
  static const double nearMissRadius = 30.0;

  // Difficulty
  static const double difficultyRampStartTime =
      10.0; // When difficulty starts rising
  static const double difficultyRampDuration = 180.0; // Seconds to reach max
  static const double maxSpeedMultiplier = 1.8;
  static const double minSpawnInterval =
      3.0; // Min seconds between hazard spawns
  static const double maxSpawnInterval = 8.0; // Starting interval
  static const int maxMineCount = 12;

  // Revive
  static const double reviveInvulnerabilityDuration = 2.5;

  // Visual
  static const double glowIntensity = 0.6;
  static const int maxParticles = 60;
  static const double particleLifespan = 1.5;
}
