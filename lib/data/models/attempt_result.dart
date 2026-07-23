/// The outcome of a single play attempt, reported by the gameplay controller to
/// the app state to drive progression, stats and daily challenges.
class AttemptResult {
  final int levelId;
  final bool won;
  final int crystalsCollected;
  final int totalCrystals;
  final int objectsUsed;
  final int par;
  final double time;
  final bool usedBoosters;
  final int magnetHits;
  final bool firstAttempt;

  const AttemptResult({
    required this.levelId,
    required this.won,
    required this.crystalsCollected,
    required this.totalCrystals,
    required this.objectsUsed,
    required this.par,
    required this.time,
    required this.usedBoosters,
    required this.magnetHits,
    required this.firstAttempt,
  });
}
