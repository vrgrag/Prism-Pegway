import 'package:flutter_test/flutter_test.dart';
import 'package:prism_pegway/engine/game_object.dart';
import 'package:prism_pegway/engine/level.dart';
import 'package:prism_pegway/engine/physics_world.dart';

void main() {
  group('Win conditions', () {
    test('cannot win while a crystal is uncollected, even over the portal', () {
      // Portal is right below the start; the crystal is parked far away and
      // unreachable, so the ball flies through the portal region but must NOT
      // win because not all crystals are collected.
      final level = LevelData(
        id: 999,
        name: 'Crystal Gate',
        backgroundIndex: 1,
        startX: 180,
        startY: 40,
        portalX: 180,
        portalY: 120,
        crystals: [GameObject(type: ObjectType.crystal, x: 20, y: 620)],
        inventory: {ObjectType.peg: 1},
        par: 1,
      );

      final world = PhysicsWorld(level: level, playerObjects: const []);
      final result = world.simulate();

      expect(
        result.won,
        false,
        reason: 'reaching the portal without all crystals must not win',
      );
      expect(result.crystalsCollected, 0);
    });

    test('collecting the crystal then reaching the portal wins', () {
      // Crystal sits directly on the straight fall line, portal below it.
      final level = LevelData(
        id: 998,
        name: 'Straight Drop',
        backgroundIndex: 1,
        startX: 180,
        startY: 40,
        portalX: 180,
        portalY: 300,
        crystals: [GameObject(type: ObjectType.crystal, x: 180, y: 160)],
        inventory: {ObjectType.peg: 1},
        par: 0,
      );

      final world = PhysicsWorld(level: level, playerObjects: const []);
      final result = world.simulate();

      expect(result.crystalsCollected, 1);
      expect(result.won, true);
    });

    test('a ball that falls out of bounds fails', () {
      final level = LevelData(
        id: 997,
        name: 'Fall Through',
        backgroundIndex: 1,
        startX: 180,
        startY: 40,
        portalX: 20,
        portalY: 20,
        crystals: [GameObject(type: ObjectType.crystal, x: 20, y: 20)],
        inventory: {ObjectType.peg: 1},
        par: 0,
      );

      final result = PhysicsWorld(
        level: level,
        playerObjects: const [],
      ).simulate();
      expect(result.won, false);
    });
  });
}
