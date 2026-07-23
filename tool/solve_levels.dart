// One-time offline tool: searches for a verified, minimal-object solution for
// every level and writes them to lib/data/level_solutions.g.dart.
//
// Run with:  dart run tool/solve_levels.dart
//
// A beam search places objects from each level's inventory on the placement
// grid and simulates with the real deterministic engine, so any solution it
// records is guaranteed to win. Because search proceeds by object count, the
// first winning depth yields the fewest objects needed (used to sanity-check
// each level's `par`).

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:prism_pegway/data/level_library.dart';
import 'package:prism_pegway/engine/config.dart';
import 'package:prism_pegway/engine/game_object.dart';
import 'package:prism_pegway/engine/level.dart';
import 'package:prism_pegway/engine/physics_world.dart';

const List<double> kDirs = [0, 45, 90, 135, 180, 225, 270, 315];
const int kBeam = 60;
const double kMinCellDist = 34; // keep placed objects on distinct cells

PhysicsWorld _sim(LevelData level, List<GameObject> placed) {
  // Good solutions finish quickly; cap sim time to keep the search fast.
  final w = PhysicsWorld(level: level, playerObjects: placed, maxTime: 16);
  w.simulate();
  return w;
}

bool _isWin(LevelData level, List<GameObject> placed) =>
    _sim(level, placed).won;

double _scoreWorld(PhysicsWorld w) {
  if (w.won) return 1e9;
  var s = w.crystalsCollected * 1e6;
  if (w.allCrystalsCollected) {
    if (w.bestPortalDist.isFinite) s += (5e4 - w.bestPortalDist);
  } else if (w.bestCrystalDist.isFinite) {
    s += (2e4 - w.bestCrystalDist);
  }
  return s;
}

double _score(LevelData level, List<GameObject> placed) =>
    _scoreWorld(_sim(level, placed));

class _State {
  final List<GameObject> placed;
  final Map<ObjectType, int> remaining;
  double score;
  _State(this.placed, this.remaining, this.score);
}

Map<ObjectType, int> _copyInv(Map<ObjectType, int> src) =>
    Map<ObjectType, int>.from(src);

List<List<double>> _candidateCells(LevelData level) {
  // Bounding region of everything relevant, expanded by two cells.
  var minX = level.startX, maxX = level.startX;
  var minY = level.startY, maxY = level.startY;
  void grow(double x, double y) {
    minX = math.min(minX, x);
    maxX = math.max(maxX, x);
    minY = math.min(minY, y);
    maxY = math.max(maxY, y);
  }

  grow(level.portalX, level.portalY);
  for (final c in level.crystals) {
    grow(c.x, c.y);
  }
  for (final o in level.fixedObjects) {
    grow(o.x, o.y);
  }
  const pad = 2 * WorldConfig.cell;
  minX -= pad;
  maxX += pad;
  minY -= pad;
  maxY += pad;

  final cells = <List<double>>[];
  for (var col = 0; col < WorldConfig.cols; col++) {
    for (var row = 0; row < WorldConfig.rows; row++) {
      final x = col * WorldConfig.cell + WorldConfig.cell / 2;
      final y = row * WorldConfig.cell + WorldConfig.cell / 2;
      if (x < minX || x > maxX || y < minY || y > maxY) continue;
      cells.add([x, y]);
    }
  }
  return cells;
}

List<List<double>> _blockedBase(LevelData level) {
  final pts = <List<double>>[];
  pts.add([level.startX, level.startY]);
  pts.add([level.portalX, level.portalY]);
  for (final c in level.crystals) {
    pts.add([c.x, c.y]);
  }
  for (final o in level.fixedObjects) {
    pts.add([o.x, o.y]);
  }
  return pts;
}

bool _cellFree(
  double x,
  double y,
  List<List<double>> base,
  List<GameObject> placed,
) {
  for (final b in base) {
    final dx = x - b[0], dy = y - b[1];
    if (dx * dx + dy * dy < kMinCellDist * kMinCellDist) return false;
  }
  for (final p in placed) {
    final dx = x - p.x, dy = y - p.y;
    if (dx * dx + dy * dy < kMinCellDist * kMinCellDist) return false;
  }
  return true;
}

String _sig(List<GameObject> placed) {
  final parts =
      placed
          .map(
            (o) =>
                '${o.type.index}:${o.x.round()}:${o.y.round()}:${o.angle.round()}:${o.link}',
          )
          .toList()
        ..sort();
  return parts.join('|');
}

List<List<GameObject>> _moves(
  _State state,
  LevelData level,
  List<List<double>> cells,
  List<List<double>> base,
) {
  final result = <List<GameObject>>[];
  for (final entry in state.remaining.entries) {
    if (entry.value <= 0) continue;
    final type = entry.key;
    if (type == ObjectType.teleporter) continue; // handled as pairs below
    for (final cell in cells) {
      if (!_cellFree(cell[0], cell[1], base, state.placed)) continue;
      if (type.isDirectional) {
        for (final a in kDirs) {
          result.add([
            GameObject(type: type, x: cell[0], y: cell[1], angle: a),
          ]);
        }
      } else {
        result.add([GameObject(type: type, x: cell[0], y: cell[1])]);
      }
    }
  }
  // Teleporter pairs (sampled with a stride to avoid combinatorial blow-up).
  final tp = state.remaining[ObjectType.teleporter] ?? 0;
  if (tp >= 2) {
    final free = <List<double>>[];
    for (var k = 0; k < cells.length; k += 2) {
      final c = cells[k];
      if (_cellFree(c[0], c[1], base, state.placed)) free.add(c);
    }
    final link = 100 + state.placed.length;
    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        result.add([
          GameObject(
            type: ObjectType.teleporter,
            x: free[i][0],
            y: free[i][1],
            link: link,
          ),
          GameObject(
            type: ObjectType.teleporter,
            x: free[j][0],
            y: free[j][1],
            link: link,
          ),
        ]);
      }
    }
  }
  return result;
}

List<GameObject>? _solve(LevelData level) {
  final cells = _candidateCells(level);
  final base = _blockedBase(level);

  if (_isWin(level, const [])) return <GameObject>[];

  var beam = <_State>[_State([], _copyInv(level.inventory), _score(level, []))];
  // Search a little past par; deeper searches rarely help and cost a lot.
  final maxObjects = math.min(level.inventoryTotal, level.par + 3);

  for (var depth = 1; depth <= maxObjects; depth++) {
    final children = <_State>[];
    final seen = <String>{};
    for (final state in beam) {
      for (final move in _moves(state, level, cells, base)) {
        final placed = [...state.placed, ...move];
        final sig = _sig(placed);
        if (!seen.add(sig)) continue;
        final w = _sim(level, placed);
        if (w.won) {
          stdout.writeln(
            '  level ${level.id}: solved with ${placed.length} object(s)',
          );
          return placed;
        }
        final rem = _copyInv(state.remaining);
        for (final o in move) {
          rem[o.type] = (rem[o.type] ?? 0) - 1;
        }
        children.add(_State(placed, rem, _scoreWorld(w)));
      }
    }
    if (children.isEmpty) break;
    children.sort((a, b) => b.score.compareTo(a.score));
    beam = children.take(kBeam).toList();
  }
  return null;
}

String _emit(GameObject o) {
  final b = StringBuffer('GameObject(type: ObjectType.${o.type.name}, ');
  b.write('x: ${o.x}, y: ${o.y}');
  if (o.angle != 0) b.write(', angle: ${o.angle}');
  if (o.variant != 0) b.write(', variant: ${o.variant}');
  if (o.link != 0) b.write(', link: ${o.link}');
  b.write(')');
  return b.toString();
}

const String _cachePath = 'tool/solutions_cache.json';

Map<int, List<GameObject>> _loadCache() {
  final f = File(_cachePath);
  final result = <int, List<GameObject>>{};
  if (!f.existsSync()) return result;
  try {
    final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    data.forEach((k, v) {
      result[int.parse(k)] = (v as List)
          .map((e) => GameObject.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  } catch (_) {}
  return result;
}

void _saveCache(Map<int, List<GameObject>> cache) {
  final map = <String, dynamic>{};
  cache.forEach((k, v) => map['$k'] = v.map((o) => o.toJson()).toList());
  File(
    _cachePath,
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(map));
}

void main(List<String> args) {
  final targets = args.map(int.parse).toSet();
  final cache = _loadCache();

  for (final level in kLevels) {
    if (targets.isNotEmpty && !targets.contains(level.id)) continue;
    final sol = _solve(level);
    if (sol == null) {
      stdout.writeln('  !! level ${level.id} (${level.name}) UNSOLVED');
      // keep any previous good solution rather than wiping it
      continue;
    }
    cache[level.id] = sol;
  }
  _saveCache(cache);

  final buffer = StringBuffer()
    ..writeln('// GENERATED by tool/solve_levels.dart. Do not edit by hand.')
    ..writeln('// Each entry is an engine-verified winning player placement.')
    ..writeln("import '../engine/game_object.dart';")
    ..writeln()
    ..writeln('final Map<int, List<GameObject>> kLevelSolutions = {');

  var missing = 0;
  for (final level in kLevels) {
    final sol = cache[level.id];
    if (sol == null) {
      missing++;
      buffer.writeln('  ${level.id}: [], // MISSING');
      continue;
    }
    if (sol.isEmpty) {
      buffer.writeln('  ${level.id}: [],');
    } else {
      buffer.writeln('  ${level.id}: [');
      for (final o in sol) {
        buffer.writeln('    ${_emit(o)},');
      }
      buffer.writeln('  ],');
    }
  }
  buffer.writeln('};');

  File('lib/data/level_solutions.g.dart').writeAsStringSync(buffer.toString());
  stdout.writeln('\nDone. Missing solutions: $missing / ${kLevels.length}');
}
