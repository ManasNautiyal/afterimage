/// Result of a single game run.
class RunResult {
  final int score;
  final double survivalTime;
  final int fragmentsCollected;
  final int ghostsSpawned;
  final int currencyEarned;
  final bool isNewBestScore;
  final bool isNewBestDuration;

  const RunResult({
    required this.score,
    required this.survivalTime,
    required this.fragmentsCollected,
    required this.ghostsSpawned,
    required this.currencyEarned,
    required this.isNewBestScore,
    required this.isNewBestDuration,
  });
}
