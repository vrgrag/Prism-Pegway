import 'package:flutter_test/flutter_test.dart';
import 'package:prism_pegway/data/game_state.dart';
import 'package:prism_pegway/data/level_library.dart';
import 'package:prism_pegway/data/models/attempt_result.dart';
import 'package:prism_pegway/data/models/daily_challenge.dart';
import 'package:prism_pegway/data/save_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

AttemptResult _win(
  int levelId, {
  int crystals = 1,
  int objects = 0,
  int magnets = 0,
  bool boosters = false,
}) {
  final level = levelById(levelId);
  return AttemptResult(
    levelId: levelId,
    won: true,
    crystalsCollected: crystals,
    totalCrystals: level.crystals.length,
    objectsUsed: objects,
    par: level.par,
    time: 5,
    usedBoosters: boosters,
    magnetHits: magnets,
    firstAttempt: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<GameState> freshState() async {
    final save = SaveManager();
    await save.init();
    final state = GameState(save);
    await state.load();
    return state;
  }

  group('Progression', () {
    test('only level 1 is unlocked on a fresh save', () async {
      final state = await freshState();
      expect(state.isUnlocked(1), true);
      expect(state.isUnlocked(2), false);
      expect(state.levelsCompleted, 0);
    });

    test('completing a level unlocks the next and records stars', () async {
      final state = await freshState();
      final level1 = levelById(1);
      state.recordAttempt(
        _win(1, crystals: level1.crystals.length, objects: 0),
      );

      expect(state.progressFor(1).completed, true);
      expect(state.progressFor(1).stars, 3); // 0 objects <= par
      expect(state.isUnlocked(2), true);
      expect(state.levelsCompleted, 1);
      expect(state.totalStars, 3);
    });

    test('progress persists across reloads', () async {
      final save = SaveManager();
      await save.init();
      final state = GameState(save);
      await state.load();
      final l1 = levelById(1);
      state.recordAttempt(_win(1, crystals: l1.crystals.length));

      // Reload with a new GameState over the same (mock) storage.
      final reloaded = GameState(save);
      await reloaded.load();
      expect(reloaded.isUnlocked(2), true);
      expect(reloaded.progressFor(1).completed, true);
      expect(reloaded.progressFor(1).stars, 3);
    });

    test('best object count keeps the minimum across attempts', () async {
      final state = await freshState();
      final l = levelById(2);
      state.recordAttempt(_win(2, crystals: l.crystals.length, objects: 4));
      expect(state.progressFor(2).bestObjects, 4);
      state.recordAttempt(_win(2, crystals: l.crystals.length, objects: 2));
      expect(state.progressFor(2).bestObjects, 2);
      state.recordAttempt(_win(2, crystals: l.crystals.length, objects: 5));
      expect(state.progressFor(2).bestObjects, 2);
    });
  });

  group('Daily challenges', () {
    test('crystal collection progresses on any attempt', () async {
      final state = await freshState();
      state.dailies = [
        DailyChallenge(type: DailyChallengeType.collectCrystals, target: 300),
      ];
      state.recordAttempt(_win(1, crystals: 5));
      expect(state.dailies.first.progress, 5);
    });

    test('completing levels progresses the completeLevels challenge', () async {
      final state = await freshState();
      state.dailies = [
        DailyChallenge(type: DailyChallengeType.completeLevels, target: 10),
      ];
      state.recordAttempt(_win(1));
      expect(state.dailies.first.progress, 1);
    });

    test('claiming a completed challenge unlocks the reward skin', () async {
      final state = await freshState();
      final challenge = DailyChallenge(
        type: DailyChallengeType.fastFinish,
        target: 1,
      );
      challenge.progress = 1;
      state.dailies = [challenge];
      expect(state.unlockedSkins.contains('vortex'), false);
      state.claimDaily(challenge);
      expect(challenge.claimed, true);
      expect(state.unlockedSkins.contains('vortex'), true);
    });
  });

  group('Skin unlocks', () {
    test('reaching the star threshold unlocks a skin', () async {
      final state = await freshState();
      // Earn 6 stars over the first two levels (3 each) -> unlocks 'pulsar'.
      state.recordAttempt(
        _win(1, crystals: levelById(1).crystals.length, objects: 0),
      );
      state.recordAttempt(
        _win(2, crystals: levelById(2).crystals.length, objects: 0),
      );
      expect(state.totalStars, greaterThanOrEqualTo(6));
      expect(state.unlockedSkins.contains('pulsar'), true);
    });
  });

  group('Corrupted save handling', () {
    test('bad json does not crash and yields defaults', () async {
      SharedPreferences.setMockInitialValues({
        'prism_pegway_save_v1': 'not-json{{',
      });
      final save = SaveManager();
      await save.init();
      final state = GameState(save);
      await state.load();
      expect(state.isUnlocked(1), true);
      expect(state.levelsCompleted, 0);
    });
  });
}
