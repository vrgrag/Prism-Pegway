class LevelProgress {
  final int levelId;
  bool unlocked;
  bool completed;
  int stars;
  int bestScore;
  int bestObjects; // fewest objects used in a win (0 = none yet)
  int attempts;

  LevelProgress({
    required this.levelId,
    this.unlocked = false,
    this.completed = false,
    this.stars = 0,
    this.bestScore = 0,
    this.bestObjects = 0,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': levelId,
    'u': unlocked,
    'c': completed,
    's': stars,
    'sc': bestScore,
    'bo': bestObjects,
    'a': attempts,
  };

  factory LevelProgress.fromJson(Map<String, dynamic> j) => LevelProgress(
    levelId: j['id'] as int,
    unlocked: j['u'] as bool? ?? false,
    completed: j['c'] as bool? ?? false,
    stars: j['s'] as int? ?? 0,
    bestScore: j['sc'] as int? ?? 0,
    bestObjects: j['bo'] as int? ?? 0,
    attempts: j['a'] as int? ?? 0,
  );
}

class PlayerStats {
  int levelsCompleted;
  int totalCrystals;
  int magnetUses;
  int totalAttempts;
  int totalStars;
  int perfectRuns; // completed on first attempt

  PlayerStats({
    this.levelsCompleted = 0,
    this.totalCrystals = 0,
    this.magnetUses = 0,
    this.totalAttempts = 0,
    this.totalStars = 0,
    this.perfectRuns = 0,
  });

  Map<String, dynamic> toJson() => {
    'lc': levelsCompleted,
    'tc': totalCrystals,
    'mu': magnetUses,
    'ta': totalAttempts,
    'ts': totalStars,
    'pr': perfectRuns,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> j) => PlayerStats(
    levelsCompleted: j['lc'] as int? ?? 0,
    totalCrystals: j['tc'] as int? ?? 0,
    magnetUses: j['mu'] as int? ?? 0,
    totalAttempts: j['ta'] as int? ?? 0,
    totalStars: j['ts'] as int? ?? 0,
    perfectRuns: j['pr'] as int? ?? 0,
  );
}
