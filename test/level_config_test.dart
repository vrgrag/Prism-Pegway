import 'package:flutter_test/flutter_test.dart';
import 'package:prism_pegway/data/level_library.dart';
import 'package:prism_pegway/data/level_solutions.g.dart';
import 'package:prism_pegway/engine/config.dart';

void main() {
  group('Level configuration', () {
    test('there are exactly 40 levels with sequential ids', () {
      expect(kLevels.length, 40);
      for (var i = 0; i < kLevels.length; i++) {
        expect(kLevels[i].id, i + 1);
      }
    });

    test('every level is well-formed', () {
      for (final level in kLevels) {
        expect(level.name.isNotEmpty, true, reason: 'level ${level.id} name');
        expect(level.backgroundIndex, inInclusiveRange(1, 8));
        expect(
          level.crystals.isNotEmpty,
          true,
          reason: 'level ${level.id} must have crystals',
        );
        expect(
          level.inventoryTotal,
          greaterThan(0),
          reason: 'level ${level.id} must offer objects to place',
        );
        expect(level.par, greaterThanOrEqualTo(0));

        // Start and portal must sit inside the field bounds.
        expect(level.startX, inInclusiveRange(0, WorldConfig.width));
        expect(level.startY, inInclusiveRange(0, WorldConfig.height));
        expect(level.portalX, inInclusiveRange(0, WorldConfig.width));
        expect(level.portalY, inInclusiveRange(0, WorldConfig.height));

        for (final c in level.crystals) {
          expect(c.x, inInclusiveRange(0, WorldConfig.width));
          expect(c.y, inInclusiveRange(0, WorldConfig.height));
        }
      }
    });

    test('every level has a generated solution entry', () {
      for (final level in kLevels) {
        expect(
          kLevelSolutions.containsKey(level.id),
          true,
          reason: 'missing solution for level ${level.id}',
        );
      }
    });

    test('solution object counts never exceed the level par target', () {
      for (final level in kLevels) {
        final sol = kLevelSolutions[level.id]!;
        expect(
          sol.length,
          lessThanOrEqualTo(level.par),
          reason:
              'level ${level.id}: min solution (${sol.length}) should be <= par (${level.par}) so 3 stars are attainable',
        );
      }
    });
  });
}
