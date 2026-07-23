import 'game_object.dart';

/// A fully data-driven level definition. Levels are authored as data (see
/// `data/level_library.dart`) rather than duplicated screens.
class LevelData {
  final int id; // 1-based level number
  final String name;
  final int backgroundIndex; // 1..8, maps to bg_location_N_asset

  /// Ball release point and its initial velocity (world units / second).
  final double startX;
  final double startY;
  final double launchVx;
  final double launchVy;

  /// Portal (goal) position.
  final double portalX;
  final double portalY;

  /// Crystals that must all be collected before the portal opens.
  final List<GameObject> crystals;

  /// Objects fixed by the level designer (pre-placed pegs, walls, magnets...).
  final List<GameObject> fixedObjects;

  /// What the player may place and how many of each.
  final Map<ObjectType, int> inventory;

  /// Target object count for a 3-star "efficient" rating.
  final int par;

  /// Optional time target (seconds) used by daily challenges.
  final double timeTarget;

  /// A known, engine-verified player placement. Used by tests and hints.
  final List<GameObject> solution;

  const LevelData({
    required this.id,
    required this.name,
    required this.backgroundIndex,
    required this.startX,
    required this.startY,
    this.launchVx = 0,
    this.launchVy = 40,
    required this.portalX,
    required this.portalY,
    required this.crystals,
    this.fixedObjects = const [],
    required this.inventory,
    required this.par,
    this.timeTarget = 20,
    this.solution = const [],
  });

  int get crystalCount => crystals.length;

  int get inventoryTotal =>
      inventory.values.fold(0, (sum, value) => sum + value);
}
