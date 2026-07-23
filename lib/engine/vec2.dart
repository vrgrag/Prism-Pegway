import 'dart:math' as math;

/// A tiny, dependency-free 2D vector used by the deterministic physics engine.
/// Kept separate from Flame so the engine can run headless in unit tests.
class Vec2 {
  double x;
  double y;

  Vec2(this.x, this.y);

  Vec2.zero() : x = 0, y = 0;

  Vec2 clone() => Vec2(x, y);

  Vec2 operator +(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 operator -(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);

  void addScaled(Vec2 o, double s) {
    x += o.x * s;
    y += o.y * s;
  }

  double dot(Vec2 o) => x * o.x + y * o.y;

  double get length => math.sqrt(x * x + y * y);
  double get length2 => x * x + y * y;

  Vec2 normalized() {
    final l = length;
    if (l < 1e-9) return Vec2(0, 0);
    return Vec2(x / l, y / l);
  }

  double distanceTo(Vec2 o) {
    final dx = x - o.x;
    final dy = y - o.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  double distanceToSquared(Vec2 o) {
    final dx = x - o.x;
    final dy = y - o.y;
    return dx * dx + dy * dy;
  }

  @override
  String toString() => 'Vec2(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// Converts a game angle (in degrees) to a unit direction vector.
/// Convention: 0 = up (0,-1); angle increases clockwise so 90 = right (1,0),
/// 180 = down (0,1), 270 = left (-1,0). This matches the on-screen rotation
/// button (each press adds 45 degrees, turning the element clockwise).
Vec2 directionFromDegrees(double degrees) {
  final r = degrees * math.pi / 180.0;
  return Vec2(math.sin(r), -math.cos(r));
}
