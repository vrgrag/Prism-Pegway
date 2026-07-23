import 'level.dart';

/// Star rating for a completed attempt. Efficiency (fewer objects) is rewarded.
/// - 0 stars: not completed
/// - 1 star : completed
/// - 2 stars: completed within par + 1 objects
/// - 3 stars: completed using at most `par` objects
int computeStars({
  required bool won,
  required int objectsUsed,
  required int par,
}) {
  if (!won) return 0;
  if (objectsUsed <= par) return 3;
  if (objectsUsed <= par + 1) return 2;
  return 1;
}

/// A numeric score used for the level's "best result" leaderboard entry.
/// Rewards collecting crystals, finishing fast and using few objects.
int computeScore({
  required LevelData level,
  required bool won,
  required int crystalsCollected,
  required int objectsUsed,
  required double time,
}) {
  if (!won) return crystalsCollected * 50;
  var score = 1000;
  score += crystalsCollected * 100;
  final saved = (level.par - objectsUsed).clamp(-99, 99);
  score += saved * 120;
  final timeBonus = ((level.timeTarget - time) * 15).round();
  if (timeBonus > 0) score += timeBonus;
  return score < 0 ? 0 : score;
}
