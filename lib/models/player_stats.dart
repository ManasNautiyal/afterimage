/// Persistent player statistics stored locally.
class PlayerStats {
  final int bestScore;
  final double bestDuration;
  final int totalCurrency;
  final Set<int> ownedSkins;
  final int selectedSkin;

  const PlayerStats({
    this.bestScore = 0,
    this.bestDuration = 0.0,
    this.totalCurrency = 0,
    this.ownedSkins = const {0},
    this.selectedSkin = 0,
  });

  PlayerStats copyWith({
    int? bestScore,
    double? bestDuration,
    int? totalCurrency,
    Set<int>? ownedSkins,
    int? selectedSkin,
  }) {
    return PlayerStats(
      bestScore: bestScore ?? this.bestScore,
      bestDuration: bestDuration ?? this.bestDuration,
      totalCurrency: totalCurrency ?? this.totalCurrency,
      ownedSkins: ownedSkins ?? this.ownedSkins,
      selectedSkin: selectedSkin ?? this.selectedSkin,
    );
  }
}
