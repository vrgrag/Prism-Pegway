import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../engine/config.dart';
import '../engine/game_object.dart';
import '../engine/level.dart';
import '../engine/physics_world.dart';
import '../engine/scoring.dart';
import '../data/level_solutions.g.dart';

enum GamePhase { editing, simulating, won, failed }

/// Owns the mutable state of a single level attempt: the objects the player has
/// placed, the active tool, and the running simulation. UI (HUD) and the Flame
/// renderer both read from this [ChangeNotifier].
class GameController extends ChangeNotifier {
  final LevelData level;
  GameController(this.level) {
    _resetInventory();
  }

  final List<GameObject> playerObjects = [];
  final Map<ObjectType, int> remaining = {};

  ObjectType? selectedTool;
  GameObject? selectedObject;

  GamePhase phase = GamePhase.editing;
  PhysicsWorld? world;

  int attemptsThisVisit = 0;
  double simTime = 0;

  // Per-attempt telemetry for scoring & daily challenges.
  bool usedBoosters = false;
  final Set<int> _magnetsTriggered = {};
  int lastCrystals = 0;

  void _resetInventory() {
    remaining.clear();
    level.inventory.forEach((k, v) => remaining[k] = v);
  }

  int get objectsUsed => playerObjects.length;
  int get totalCrystals => level.crystals.length;

  int get crystalsCollected => world?.crystalsCollected ?? 0;

  bool get isSimulating => phase == GamePhase.simulating;
  bool get isEditing => phase == GamePhase.editing;

  // --- Tool / selection -------------------------------------------------------

  void selectTool(ObjectType? type) {
    if (phase != GamePhase.editing) return;
    selectedTool = (selectedTool == type) ? null : type;
    selectedObject = null;
    notifyListeners();
  }

  void selectObject(GameObject? obj) {
    if (phase != GamePhase.editing) return;
    selectedObject = obj;
    notifyListeners();
  }

  // --- Placement --------------------------------------------------------------

  /// Snaps a world position to the nearest grid cell centre.
  static double snap(double v) =>
      (v / WorldConfig.cell).floorToDouble() * WorldConfig.cell +
      WorldConfig.cell / 2;

  bool _insideField(double x, double y) =>
      x > 12 &&
      x < WorldConfig.width - 12 &&
      y > 12 &&
      y < WorldConfig.height - 12;

  bool _overlaps(double x, double y, {GameObject? ignore}) {
    const minDist = 30.0;
    bool near(double ox, double oy) =>
        (x - ox) * (x - ox) + (y - oy) * (y - oy) < minDist * minDist;

    if (near(level.startX, level.startY)) return true;
    if (near(level.portalX, level.portalY)) return true;
    for (final c in level.crystals) {
      if (near(c.x, c.y)) return true;
    }
    for (final o in level.fixedObjects) {
      if (near(o.x, o.y)) return true;
    }
    for (final o in playerObjects) {
      if (o == ignore) continue;
      if (near(o.x, o.y)) return true;
    }
    return false;
  }

  bool canPlaceAt(ObjectType type, double worldX, double worldY) {
    final x = snap(worldX);
    final y = snap(worldY);
    if (!_insideField(x, y)) return false;
    if (_overlaps(x, y)) return false;
    return (remaining[type] ?? 0) > 0;
  }

  bool placeAt(ObjectType type, double worldX, double worldY) {
    if (phase != GamePhase.editing) return false;
    if (!canPlaceAt(type, worldX, worldY)) return false;
    final x = snap(worldX);
    final y = snap(worldY);
    final link = type == ObjectType.teleporter ? _nextTeleporterLink() : 0;
    final obj = GameObject(type: type, x: x, y: y, link: link);
    playerObjects.add(obj);
    remaining[type] = (remaining[type] ?? 0) - 1;
    selectedObject = obj;
    if ((remaining[type] ?? 0) == 0 && selectedTool == type) {
      selectedTool = null;
    }
    notifyListeners();
    return true;
  }

  int _nextTeleporterLink() {
    // Pair teleporters two-by-two: the newest unpaired teleporter shares a link.
    final links = playerObjects
        .where((o) => o.type == ObjectType.teleporter)
        .map((o) => o.link)
        .toList();
    final counts = <int, int>{};
    for (final l in links) {
      counts[l] = (counts[l] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      if (entry.value == 1) return entry.key; // pair with the lonely one
    }
    return (counts.keys.isEmpty ? 0 : counts.keys.reduce(math.max)) + 1;
  }

  bool moveSelected(double worldX, double worldY) {
    final obj = selectedObject;
    if (obj == null || phase != GamePhase.editing) return false;
    final x = snap(worldX);
    final y = snap(worldY);
    if (!_insideField(x, y)) return false;
    if (_overlaps(x, y, ignore: obj)) return false;
    obj.x = x;
    obj.y = y;
    notifyListeners();
    return true;
  }

  void rotateSelected() {
    final obj = selectedObject;
    if (obj == null || phase != GamePhase.editing) return;
    if (!obj.type.isDirectional) return;
    obj.angle = (obj.angle + 45) % 360;
    notifyListeners();
  }

  /// Places the next object from the level's verified solution that the player
  /// hasn't placed yet — a gentle nudge rather than a full auto-solve.
  /// Returns true if a hint object was added.
  bool applyHint() {
    if (phase != GamePhase.editing) return false;
    final sol = kLevelSolutions[level.id];
    if (sol == null || sol.isEmpty) return false;
    for (final s in sol) {
      if (objectAt(s.x, s.y) != null) continue;
      if (s.type == ObjectType.teleporter) {
        final pair = sol
            .where((o) => o.type == ObjectType.teleporter && o.link == s.link)
            .toList();
        if ((remaining[ObjectType.teleporter] ?? 0) < pair.length) continue;
        var placedAny = false;
        for (final t in pair) {
          if (objectAt(t.x, t.y) != null) continue;
          playerObjects.add(t.clone());
          remaining[ObjectType.teleporter] =
              (remaining[ObjectType.teleporter] ?? 0) - 1;
          placedAny = true;
        }
        if (placedAny) {
          selectedObject = null;
          notifyListeners();
          return true;
        }
        continue;
      }
      if ((remaining[s.type] ?? 0) <= 0) continue;
      final obj = s.clone();
      playerObjects.add(obj);
      remaining[s.type] = (remaining[s.type] ?? 0) - 1;
      selectedObject = obj;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeSelected() {
    final obj = selectedObject;
    if (obj == null || phase != GamePhase.editing) return;
    playerObjects.remove(obj);
    remaining[obj.type] = (remaining[obj.type] ?? 0) + 1;
    selectedObject = null;
    notifyListeners();
  }

  GameObject? objectAt(double worldX, double worldY) {
    GameObject? best;
    var bestD = 26.0 * 26.0;
    for (final o in playerObjects) {
      final d =
          (o.x - worldX) * (o.x - worldX) + (o.y - worldY) * (o.y - worldY);
      if (d < bestD) {
        bestD = d;
        best = o;
      }
    }
    return best;
  }

  // --- Simulation -------------------------------------------------------------

  void launch() {
    if (phase != GamePhase.editing) return;
    world = PhysicsWorld(level: level, playerObjects: cloneObjects());
    world!.launch();
    phase = GamePhase.simulating;
    selectedObject = null;
    selectedTool = null;
    simTime = 0;
    usedBoosters = false;
    _magnetsTriggered.clear();
    lastCrystals = 0;
    attemptsThisVisit += 1;
    notifyListeners();
  }

  List<GameObject> cloneObjects() =>
      playerObjects.map((o) => o.clone()).toList();

  void onSimResolved() {
    final w = world;
    if (w == null) return;
    phase = w.won ? GamePhase.won : GamePhase.failed;
    notifyListeners();
  }

  void backToEdit() {
    phase = GamePhase.editing;
    world = null;
    simTime = 0;
    notifyListeners();
  }

  int get finalStars => computeStars(
    won: phase == GamePhase.won,
    objectsUsed: objectsUsed,
    par: level.par,
  );

  int get finalScore => computeScore(
    level: level,
    won: phase == GamePhase.won,
    crystalsCollected: crystalsCollected,
    objectsUsed: objectsUsed,
    time: simTime,
  );

  void noteMagnetTriggered(int key) => _magnetsTriggered.add(key);
  void noteBoosterUsed() => usedBoosters = true;
  int get magnetHits => _magnetsTriggered.length;
}
