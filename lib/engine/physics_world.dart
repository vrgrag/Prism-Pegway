import 'dart:math' as math;

import 'config.dart';
import 'game_object.dart';
import 'level.dart';
import 'sim_event.dart';
import 'vec2.dart';

class _Peg {
  final double x, y, r;
  _Peg(this.x, this.y, this.r);
}

class _Wall {
  final double cx, cy, hw, hh;
  _Wall(this.cx, this.cy, this.hw, this.hh);
}

class _CrystalState {
  final Vec2 pos;
  bool collected = false;
  _CrystalState(this.pos);
}

/// Deterministic, dependency-free physics simulation for one level attempt.
///
/// A custom fixed-step engine is used instead of Forge2D/Box2D because the
/// special objects (booster, spring, magnet, prism, teleporter) need precise,
/// author-tunable behaviour and, above all, identical results on every restart
/// and on every device. A fixed-timestep integrator with explicit collision
/// resolution gives that determinism cleanly; the same engine runs headless in
/// unit tests to prove all 40 levels are solvable.
class PhysicsWorld {
  final LevelData level;
  final double gravity;
  final double maxSimTime;

  final Vec2 ballPos = Vec2.zero();
  final Vec2 ballVel = Vec2.zero();
  final double ballRadius = WorldConfig.ballRadius;

  bool launched = false;
  bool won = false;
  bool failed = false;
  bool timedOut = false;
  double time = 0;
  double _settleTimer = 0;

  /// Closest the ball ever got to the portal after collecting every crystal,
  /// and to the nearest uncollected crystal overall. Used by the offline solver
  /// to score near-miss attempts and guide the search.
  double bestPortalDist = double.infinity;
  double bestCrystalDist = double.infinity;

  final List<_Peg> _pegs = [];
  final List<_Wall> _walls = [];
  final List<GameObject> _boosters = [];
  final List<GameObject> _springs = [];
  final List<double> _springCd = [];
  final List<GameObject> _magnets = [];
  final List<GameObject> _prisms = [];
  final List<double> _prismCd = [];
  final List<GameObject> _teleporters = [];
  final List<int> _teleporterPartner = [];
  final List<double> _teleporterCd = [];
  final List<_CrystalState> _crystals = [];
  late final Vec2 _portal;

  /// Events produced since the last drain. The render layer reads and clears.
  final List<SimEvent> events = [];

  PhysicsWorld({
    required this.level,
    required List<GameObject> playerObjects,
    double? gravityOverride,
    double? maxTime,
  }) : gravity = gravityOverride ?? WorldConfig.defaultGravity,
       maxSimTime = maxTime ?? Physics.maxSimTime {
    ballPos.x = level.startX;
    ballPos.y = level.startY;
    _portal = Vec2(level.portalX, level.portalY);

    // Field borders: left, right, top (bottom is open -> falling out = fail).
    const w = WorldConfig.width;
    const h = WorldConfig.height;
    _walls.add(_Wall(-20, h / 2, 20, h * 2));
    _walls.add(_Wall(w + 20, h / 2, 20, h * 2));
    _walls.add(_Wall(w / 2, -20, w * 2, 20));

    for (final c in level.crystals) {
      _crystals.add(_CrystalState(Vec2(c.x, c.y)));
    }

    final all = <GameObject>[...level.fixedObjects, ...playerObjects];
    // First pass: register teleporters so we can link partners by order/link.
    for (final o in all) {
      switch (o.type) {
        case ObjectType.peg:
          _pegs.add(_Peg(o.x, o.y, Physics.pegRadius));
          break;
        case ObjectType.wall:
          _walls.add(_Wall(o.x, o.y, o.halfWidth, o.halfHeight));
          break;
        case ObjectType.booster:
          _boosters.add(o);
          break;
        case ObjectType.spring:
          _springs.add(o);
          _springCd.add(0);
          break;
        case ObjectType.magnet:
          _magnets.add(o);
          break;
        case ObjectType.prism:
          _prisms.add(o);
          _prismCd.add(0);
          break;
        case ObjectType.teleporter:
          _teleporters.add(o);
          _teleporterCd.add(0);
          break;
        case ObjectType.crystal:
          _crystals.add(_CrystalState(Vec2(o.x, o.y)));
          break;
        case ObjectType.portal:
        case ObjectType.start:
          break;
      }
    }
    _linkTeleporters();
  }

  void _linkTeleporters() {
    for (var i = 0; i < _teleporters.length; i++) {
      var partner = -1;
      for (var j = 0; j < _teleporters.length; j++) {
        if (i == j) continue;
        if (_teleporters[j].link == _teleporters[i].link) {
          partner = j;
          break;
        }
      }
      _teleporterPartner.add(partner);
    }
  }

  int get totalCrystals => _crystals.length;
  int get crystalsCollected => _crystals.where((c) => c.collected).length;
  bool get allCrystalsCollected => _crystals.every((c) => c.collected);
  bool get finished => won || failed;

  bool crystalCollected(int index) => _crystals[index].collected;

  void launch() {
    if (launched) return;
    launched = true;
    ballVel.x = level.launchVx;
    ballVel.y = level.launchVy;
  }

  /// Advances the simulation by [dt] real seconds using fixed sub-steps so the
  /// result is independent of frame rate.
  void advance(double dt) {
    if (!launched || finished) return;
    var remaining = dt;
    // Cap catch-up to avoid spiral-of-death after a stall.
    if (remaining > 0.1) remaining = 0.1;
    while (remaining > 1e-6 && !finished) {
      final step = remaining < Physics.fixedDt ? remaining : Physics.fixedDt;
      _step(step);
      remaining -= step;
    }
  }

  void _step(double dt) {
    // --- Accumulate accelerations (gravity + magnets + boosters) ---
    var ax = 0.0;
    var ay = gravity;

    for (final m in _magnets) {
      final dx = m.x - ballPos.x;
      final dy = m.y - ballPos.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < Physics.magnetInfluence && dist > 1) {
        final eff = dist < Physics.magnetMinDist ? Physics.magnetMinDist : dist;
        final f = Physics.magnetStrength / (eff * eff);
        ax += (dx / dist) * f;
        ay += (dy / dist) * f;
        _emit(SimEventType.magnet, m.x, m.y);
      }
    }

    for (final b in _boosters) {
      if ((ballPos.x - b.x).abs() < Physics.boosterHalf + ballRadius &&
          (ballPos.y - b.y).abs() < Physics.boosterHalf + ballRadius) {
        final dir = directionFromDegrees(b.angle);
        ax += dir.x * Physics.boosterAccel;
        ay += dir.y * Physics.boosterAccel;
        _emit(SimEventType.booster, b.x, b.y);
      }
    }

    ballVel.x += ax * dt;
    ballVel.y += ay * dt;

    // Gentle drag keeps speeds bounded and the sim stable.
    final dragFactor = 1 - Physics.airDrag;
    ballVel.x *= dragFactor;
    ballVel.y *= dragFactor;

    final speed = ballVel.length;
    if (speed > Physics.maxSpeed) {
      final s = Physics.maxSpeed / speed;
      ballVel.x *= s;
      ballVel.y *= s;
    }

    // --- Integrate ---
    ballPos.x += ballVel.x * dt;
    ballPos.y += ballVel.y * dt;

    // --- Peg collisions ---
    for (final p in _pegs) {
      final dx = ballPos.x - p.x;
      final dy = ballPos.y - p.y;
      final rr = p.r + ballRadius;
      final d2 = dx * dx + dy * dy;
      if (d2 < rr * rr) {
        final d = math.sqrt(d2);
        final nx = d < 1e-6 ? 0.0 : dx / d;
        final ny = d < 1e-6 ? -1.0 : dy / d;
        final overlap = rr - d;
        ballPos.x += nx * overlap;
        ballPos.y += ny * overlap;
        final vn = ballVel.x * nx + ballVel.y * ny;
        if (vn < 0) {
          final j = (1 + Physics.restitution) * vn;
          ballVel.x -= j * nx;
          ballVel.y -= j * ny;
          _emit(SimEventType.bounce, p.x, p.y);
        }
      }
    }

    // --- Wall collisions ---
    for (final w in _walls) {
      final closestX = ballPos.x.clamp(w.cx - w.hw, w.cx + w.hw);
      final closestY = ballPos.y.clamp(w.cy - w.hh, w.cy + w.hh);
      final dx = ballPos.x - closestX;
      final dy = ballPos.y - closestY;
      final d2 = dx * dx + dy * dy;
      if (d2 < ballRadius * ballRadius) {
        double nx, ny;
        double d;
        if (d2 > 1e-6) {
          d = math.sqrt(d2);
          nx = dx / d;
          ny = dy / d;
        } else {
          // Ball centre inside the box: push out along the shallowest axis.
          final left = (ballPos.x - (w.cx - w.hw)).abs();
          final right = ((w.cx + w.hw) - ballPos.x).abs();
          final top = (ballPos.y - (w.cy - w.hh)).abs();
          final bottom = ((w.cy + w.hh) - ballPos.y).abs();
          final minH = math.min(left, right);
          final minV = math.min(top, bottom);
          if (minH < minV) {
            nx = left < right ? -1 : 1;
            ny = 0;
          } else {
            nx = 0;
            ny = top < bottom ? -1 : 1;
          }
          d = 0;
        }
        final overlap = ballRadius - d;
        ballPos.x += nx * overlap;
        ballPos.y += ny * overlap;
        final vn = ballVel.x * nx + ballVel.y * ny;
        if (vn < 0) {
          final j = (1 + Physics.wallRestitution) * vn;
          ballVel.x -= j * nx;
          ballVel.y -= j * ny;
          _emit(SimEventType.wall, closestX, closestY);
        }
      }
    }

    // --- Springs ---
    for (var i = 0; i < _springs.length; i++) {
      if (_springCd[i] > 0) {
        _springCd[i] -= dt;
        continue;
      }
      final s = _springs[i];
      final rr = Physics.springRadius + ballRadius;
      if (ballPos.distanceToSquared(Vec2(s.x, s.y)) < rr * rr) {
        final dir = directionFromDegrees(s.angle);
        ballVel.x = dir.x * Physics.springPower;
        ballVel.y = dir.y * Physics.springPower;
        _springCd[i] = 0.25;
        _emit(SimEventType.spring, s.x, s.y);
      }
    }

    // --- Prisms (instant redirect along fixed beam) ---
    for (var i = 0; i < _prisms.length; i++) {
      if (_prismCd[i] > 0) {
        _prismCd[i] -= dt;
        continue;
      }
      final p = _prisms[i];
      final rr = Physics.prismRadius + ballRadius;
      if (ballPos.distanceToSquared(Vec2(p.x, p.y)) < rr * rr) {
        final dir = directionFromDegrees(p.angle);
        final sp = math.max(ballVel.length, Physics.prismSpeed);
        ballVel.x = dir.x * sp;
        ballVel.y = dir.y * sp;
        _prismCd[i] = 0.2;
        _emit(SimEventType.prism, p.x, p.y);
      }
    }

    // --- Teleporters ---
    for (var i = 0; i < _teleporters.length; i++) {
      if (_teleporterCd[i] > 0) {
        _teleporterCd[i] -= dt;
        continue;
      }
      final t = _teleporters[i];
      final rr = Physics.teleporterRadius + ballRadius;
      if (ballPos.distanceToSquared(Vec2(t.x, t.y)) < rr * rr) {
        final partner = _teleporterPartner[i];
        if (partner >= 0) {
          final dest = _teleporters[partner];
          final dir = ballVel.length < 1e-3 ? Vec2(0, 1) : ballVel.normalized();
          ballPos.x = dest.x + dir.x * (rr + 2);
          ballPos.y = dest.y + dir.y * (rr + 2);
          _teleporterCd[i] = 0.4;
          _teleporterCd[partner] = 0.4;
          _emit(SimEventType.teleport, dest.x, dest.y);
        }
      }
    }

    // --- Crystals ---
    var nearestUncollected = double.infinity;
    for (final c in _crystals) {
      if (c.collected) continue;
      final rr = Physics.crystalRadius + ballRadius;
      final dc = ballPos.distanceTo(c.pos);
      if (dc < nearestUncollected) nearestUncollected = dc;
      if (dc < rr) {
        c.collected = true;
        _emit(SimEventType.crystal, c.pos.x, c.pos.y);
      }
    }
    if (nearestUncollected < bestCrystalDist) {
      bestCrystalDist = nearestUncollected;
    }

    // --- Portal / win ---
    if (allCrystalsCollected) {
      final dPortal = ballPos.distanceTo(_portal);
      if (dPortal < bestPortalDist) bestPortalDist = dPortal;
      final rr = Physics.portalCapture;
      if (ballPos.distanceToSquared(_portal) < rr * rr) {
        won = true;
        _emit(SimEventType.win, _portal.x, _portal.y);
        return;
      }
    }

    // --- Failure conditions ---
    if (ballPos.y > WorldConfig.height + 60 ||
        ballPos.x < -80 ||
        ballPos.x > WorldConfig.width + 80) {
      failed = true;
      _emit(SimEventType.fail, ballPos.x, ballPos.y);
      return;
    }

    if (speed < Physics.settleSpeed) {
      _settleTimer += dt;
      if (_settleTimer > Physics.settleTime) {
        failed = true;
        _emit(SimEventType.fail, ballPos.x, ballPos.y);
        return;
      }
    } else {
      _settleTimer = 0;
    }

    time += dt;
    if (time > maxSimTime) {
      failed = true;
      timedOut = true;
      _emit(SimEventType.fail, ballPos.x, ballPos.y);
    }
  }

  void _emit(SimEventType type, double x, double y) {
    events.add(SimEvent(type, x, y));
  }

  /// Runs the whole attempt headless and returns the outcome. Used by tests.
  SimResult simulate() {
    launch();
    while (!finished) {
      _step(Physics.fixedDt);
    }
    return SimResult(
      won: won,
      timedOut: timedOut,
      crystalsCollected: crystalsCollected,
      totalCrystals: totalCrystals,
      time: time,
    );
  }
}
