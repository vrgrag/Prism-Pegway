import 'package:flutter_test/flutter_test.dart';
import 'package:prism_pegway/data/level_library.dart';
import 'package:prism_pegway/data/level_solutions.g.dart';
import 'package:prism_pegway/engine/physics_world.dart';

void main() {
  group('Every level is solvable with its verified solution', () {
    for (final level in kLevels) {
      test('level ${level.id} (${level.name}) is winnable', () {
        final solution = kLevelSolutions[level.id]!;
        final world = PhysicsWorld(
          level: level,
          playerObjects: solution.map((o) => o.clone()).toList(),
        );
        final result = world.simulate();

        expect(
          result.won,
          true,
          reason: 'level ${level.id} solution did not reach the portal',
        );
        expect(
          result.crystalsCollected,
          level.crystals.length,
          reason: 'level ${level.id} did not collect all crystals',
        );
        expect(result.allCrystalsCollected, true);
      });
    }

    test('the simulation is deterministic across runs', () {
      final level = kLevels[9];
      final sol = kLevelSolutions[level.id]!;
      final a = PhysicsWorld(
        level: level,
        playerObjects: sol.map((o) => o.clone()).toList(),
      ).simulate();
      final b = PhysicsWorld(
        level: level,
        playerObjects: sol.map((o) => o.clone()).toList(),
      ).simulate();
      expect(a.won, b.won);
      expect(a.crystalsCollected, b.crystalsCollected);
      expect(a.time, closeTo(b.time, 1e-9));
    });
  });
}
