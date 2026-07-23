import 'package:flutter_test/flutter_test.dart';
import 'package:prism_pegway/engine/level.dart';
import 'package:prism_pegway/engine/game_object.dart';
import 'package:prism_pegway/engine/scoring.dart';

void main() {
  group('Star rating', () {
    test('no stars when the level is not completed', () {
      expect(computeStars(won: false, objectsUsed: 1, par: 3), 0);
    });

    test('three stars at or under par', () {
      expect(computeStars(won: true, objectsUsed: 3, par: 3), 3);
      expect(computeStars(won: true, objectsUsed: 2, par: 3), 3);
    });

    test('two stars at par + 1', () {
      expect(computeStars(won: true, objectsUsed: 4, par: 3), 2);
    });

    test('one star when well over par', () {
      expect(computeStars(won: true, objectsUsed: 8, par: 3), 1);
    });
  });

  group('Score', () {
    final level = LevelData(
      id: 1,
      name: 't',
      backgroundIndex: 1,
      startX: 0,
      startY: 0,
      portalX: 0,
      portalY: 0,
      crystals: [GameObject(type: ObjectType.crystal, x: 0, y: 0)],
      inventory: {ObjectType.peg: 3},
      par: 3,
      timeTarget: 20,
    );

    test('failing returns only partial crystal credit', () {
      final s = computeScore(
        level: level,
        won: false,
        crystalsCollected: 1,
        objectsUsed: 2,
        time: 5,
      );
      expect(s, 50);
    });

    test('fewer objects and faster time score higher', () {
      final efficient = computeScore(
        level: level,
        won: true,
        crystalsCollected: 1,
        objectsUsed: 1,
        time: 4,
      );
      final wasteful = computeScore(
        level: level,
        won: true,
        crystalsCollected: 1,
        objectsUsed: 5,
        time: 18,
      );
      expect(efficient, greaterThan(wasteful));
    });
  });
}
