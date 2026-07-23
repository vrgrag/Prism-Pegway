enum DailyChallengeType {
  completeLevels,
  collectCrystals,
  useMagnets,
  firstAttempt,
  minObjects,
  fastFinish,
  noBoosters,
}

extension DailyChallengeInfo on DailyChallengeType {
  String get title {
    switch (this) {
      case DailyChallengeType.completeLevels:
        return 'Route Master';
      case DailyChallengeType.collectCrystals:
        return 'Crystal Hoarder';
      case DailyChallengeType.useMagnets:
        return 'Magnetic Mind';
      case DailyChallengeType.firstAttempt:
        return 'First Try Genius';
      case DailyChallengeType.minObjects:
        return 'Minimalist';
      case DailyChallengeType.fastFinish:
        return 'Speed Runner';
      case DailyChallengeType.noBoosters:
        return 'Purist';
    }
  }

  String describe(int target) {
    switch (this) {
      case DailyChallengeType.completeLevels:
        return 'Complete $target levels.';
      case DailyChallengeType.collectCrystals:
        return 'Collect $target crystals.';
      case DailyChallengeType.useMagnets:
        return 'Use magnets $target times.';
      case DailyChallengeType.firstAttempt:
        return 'Complete a level on the first attempt.';
      case DailyChallengeType.minObjects:
        return 'Finish using the minimum number of objects.';
      case DailyChallengeType.fastFinish:
        return 'Finish a simulation in under 20 seconds.';
      case DailyChallengeType.noBoosters:
        return 'Collect all crystals without boosters.';
    }
  }

  int get defaultTarget {
    switch (this) {
      case DailyChallengeType.completeLevels:
        return 10;
      case DailyChallengeType.collectCrystals:
        return 300;
      case DailyChallengeType.useMagnets:
        return 30;
      case DailyChallengeType.firstAttempt:
      case DailyChallengeType.minObjects:
      case DailyChallengeType.fastFinish:
      case DailyChallengeType.noBoosters:
        return 1;
    }
  }
}

class DailyChallenge {
  final DailyChallengeType type;
  final int target;
  int progress;
  bool claimed;

  DailyChallenge({
    required this.type,
    required this.target,
    this.progress = 0,
    this.claimed = false,
  });

  bool get completed => progress >= target;
  double get ratio => target == 0 ? 0 : (progress / target).clamp(0, 1);

  Map<String, dynamic> toJson() => {
    't': type.index,
    'g': target,
    'p': progress,
    'c': claimed,
  };

  factory DailyChallenge.fromJson(Map<String, dynamic> j) => DailyChallenge(
    type: DailyChallengeType.values[j['t'] as int],
    target: j['g'] as int,
    progress: j['p'] as int? ?? 0,
    claimed: j['c'] as bool? ?? false,
  );
}
