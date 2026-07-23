import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/audio_manager.dart';
import '../core/haptics.dart';
import '../engine/scoring.dart';
import 'level_library.dart';
import 'models/attempt_result.dart';
import 'models/ball_skin.dart';
import 'models/daily_challenge.dart';
import 'models/level_progress.dart';
import 'models/settings.dart';
import 'save_manager.dart';

/// Single source of truth for all persistent player data. Extends
/// [ChangeNotifier] so widgets rebuild via [ListenableBuilder] without any
/// third-party state package.
class GameState extends ChangeNotifier {
  final SaveManager _saver;
  GameState(this._saver);

  GameSettings settings = GameSettings();
  final Map<int, LevelProgress> progress = {};
  PlayerStats stats = PlayerStats();
  List<DailyChallenge> dailies = [];
  String dailyDate = '';
  Set<String> unlockedSkins = {'prism'};
  String selectedSkin = 'prism';
  bool tutorialSeen = false;

  // --- Loading / init ---------------------------------------------------------

  Future<void> saverInit() => _saver.init();

  Future<void> load() async {
    final data = _saver.load();
    try {
      if (data['settings'] is Map) {
        settings = GameSettings.fromJson(
          Map<String, dynamic>.from(data['settings'] as Map),
        );
      }
      if (data['stats'] is Map) {
        stats = PlayerStats.fromJson(
          Map<String, dynamic>.from(data['stats'] as Map),
        );
      }
      if (data['progress'] is List) {
        for (final p in data['progress'] as List) {
          final lp = LevelProgress.fromJson(
            Map<String, dynamic>.from(p as Map),
          );
          progress[lp.levelId] = lp;
        }
      }
      unlockedSkins = {
        ...((data['skins'] as List?)?.cast<String>() ?? const ['prism']),
      };
      selectedSkin = data['skin'] as String? ?? 'prism';
      tutorialSeen = data['tutorialSeen'] as bool? ?? false;
      dailyDate = data['dailyDate'] as String? ?? '';
      if (data['dailies'] is List) {
        dailies = (data['dailies'] as List)
            .map(
              (e) =>
                  DailyChallenge.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
    } catch (_) {
      // Corrupted field(s): fall back to defaults already assigned above.
    }

    _ensureLevelDefaults();
    if (!unlockedSkins.contains('prism')) unlockedSkins.add('prism');
    _refreshDailyIfNeeded();
    _syncSkinUnlocks();
    _applyAudioAndHaptics();
    notifyListeners();
  }

  void _ensureLevelDefaults() {
    for (final level in kLevels) {
      progress.putIfAbsent(
        level.id,
        () => LevelProgress(levelId: level.id, unlocked: level.id == 1),
      );
    }
    // Level 1 is always available.
    progress[1]!.unlocked = true;
  }

  void _applyAudioAndHaptics() {
    Haptics.enabled = settings.hapticsOn;
    AudioManager.instance.applySettings(
      music: settings.musicOn,
      sound: settings.soundOn,
      musicVol: settings.musicVolume,
      effectsVol: settings.effectsVolume,
    );
  }

  // --- Derived values ---------------------------------------------------------

  int get totalStars => progress.values.fold(0, (sum, p) => sum + p.stars);

  int get levelsCompleted => progress.values.where((p) => p.completed).length;

  int get highestUnlocked {
    var highest = 1;
    for (final p in progress.values) {
      if (p.unlocked && p.levelId > highest) highest = p.levelId;
    }
    return highest;
  }

  bool isUnlocked(int levelId) => progress[levelId]?.unlocked ?? false;
  LevelProgress progressFor(int levelId) =>
      progress[levelId] ??
      (progress[levelId] = LevelProgress(levelId: levelId));

  // --- Settings ---------------------------------------------------------------

  void updateSettings(GameSettings s) {
    settings = s;
    _applyAudioAndHaptics();
    _save();
    notifyListeners();
  }

  // --- Skins ------------------------------------------------------------------

  bool isSkinUnlocked(BallSkin skin) => unlockedSkins.contains(skin.id);

  void selectSkin(String id) {
    if (!unlockedSkins.contains(id)) return;
    selectedSkin = id;
    _save();
    notifyListeners();
  }

  /// Unlocks star-gated skins whenever the star total is high enough.
  List<BallSkin> _syncSkinUnlocks() {
    final newly = <BallSkin>[];
    final stars = totalStars;
    for (final skin in kBallSkins) {
      if (skin.dailyReward) continue;
      if (!unlockedSkins.contains(skin.id) && stars >= skin.starsRequired) {
        unlockedSkins.add(skin.id);
        if (skin.starsRequired > 0) newly.add(skin);
      }
    }
    return newly;
  }

  void unlockDailyRewardSkin() {
    final reward = kBallSkins.firstWhere(
      (s) => s.dailyReward,
      orElse: () => kBallSkins.first,
    );
    if (!unlockedSkins.contains(reward.id)) {
      unlockedSkins.add(reward.id);
      _save();
      notifyListeners();
    }
  }

  // --- Tutorial ---------------------------------------------------------------

  void markTutorialSeen() {
    if (tutorialSeen) return;
    tutorialSeen = true;
    _save();
    notifyListeners();
  }

  // --- Daily challenges -------------------------------------------------------

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _refreshDailyIfNeeded() {
    final today = _todayKey();
    if (dailyDate == today && dailies.isNotEmpty) return;
    dailyDate = today;
    dailies = _generateDailies(today);
  }

  List<DailyChallenge> _generateDailies(String seedKey) {
    final seed = seedKey.codeUnits.fold(0, (a, b) => a + b);
    final rng = math.Random(seed);
    final types = List<DailyChallengeType>.from(DailyChallengeType.values)
      ..shuffle(rng);
    final chosen = types.take(3).toList();
    return chosen
        .map((t) => DailyChallenge(type: t, target: t.defaultTarget))
        .toList();
  }

  void claimDaily(DailyChallenge challenge) {
    if (!challenge.completed || challenge.claimed) return;
    challenge.claimed = true;
    unlockDailyRewardSkin();
    _save();
    notifyListeners();
  }

  void _progressDaily(DailyChallengeType type, int amount) {
    for (final d in dailies) {
      if (d.type == type && !d.completed) {
        d.progress = math.min(d.target, d.progress + amount);
      }
    }
  }

  // --- Recording an attempt ---------------------------------------------------

  /// Returns any skins that were newly unlocked so the UI can celebrate them.
  List<BallSkin> recordAttempt(AttemptResult r) {
    final lp = progressFor(r.levelId);
    lp.attempts += 1;
    stats.totalAttempts += 1;
    stats.totalCrystals += r.crystalsCollected;
    stats.magnetUses += r.magnetHits;

    _progressDaily(DailyChallengeType.collectCrystals, r.crystalsCollected);
    _progressDaily(DailyChallengeType.useMagnets, r.magnetHits);

    if (r.won) {
      final stars = computeStars(
        won: true,
        objectsUsed: r.objectsUsed,
        par: r.par,
      );
      final score = computeScore(
        level: levelById(r.levelId),
        won: true,
        crystalsCollected: r.crystalsCollected,
        objectsUsed: r.objectsUsed,
        time: r.time,
      );
      final firstCompletion = !lp.completed;
      lp.completed = true;
      lp.stars = math.max(lp.stars, stars);
      lp.bestScore = math.max(lp.bestScore, score);
      lp.bestObjects = lp.bestObjects == 0
          ? r.objectsUsed
          : math.min(lp.bestObjects, r.objectsUsed);

      if (firstCompletion) stats.levelsCompleted += 1;
      if (r.firstAttempt) stats.perfectRuns += 1;

      // Unlock next level.
      final next = progress[r.levelId + 1];
      if (next != null) next.unlocked = true;

      // Daily challenge progress for wins.
      _progressDaily(DailyChallengeType.completeLevels, 1);
      if (r.firstAttempt) {
        _progressDaily(DailyChallengeType.firstAttempt, 1);
      }
      if (r.objectsUsed <= r.par) {
        _progressDaily(DailyChallengeType.minObjects, 1);
      }
      if (r.time < 20) {
        _progressDaily(DailyChallengeType.fastFinish, 1);
      }
      if (!r.usedBoosters) {
        _progressDaily(DailyChallengeType.noBoosters, 1);
      }
    }

    stats.totalStars = totalStars;
    final newSkins = _syncSkinUnlocks();
    _save();
    notifyListeners();
    return newSkins;
  }

  // --- Persistence ------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'settings': settings.toJson(),
    'stats': stats.toJson(),
    'progress': progress.values.map((p) => p.toJson()).toList(),
    'skins': unlockedSkins.toList(),
    'skin': selectedSkin,
    'tutorialSeen': tutorialSeen,
    'dailyDate': dailyDate,
    'dailies': dailies.map((d) => d.toJson()).toList(),
  };

  void _save() {
    _saver.save(toJson());
  }

  /// Wipes all progress (used by Settings -> reset).
  Future<void> resetProgress() async {
    progress.clear();
    stats = PlayerStats();
    unlockedSkins = {'prism'};
    selectedSkin = 'prism';
    tutorialSeen = false;
    dailies = _generateDailies(_todayKey());
    dailyDate = _todayKey();
    _ensureLevelDefaults();
    _save();
    notifyListeners();
  }
}
