import 'game_object.dart';

/// Fixed virtual playfield dimensions (world units). The renderer scales this
/// to the device width; a fixed world keeps physics identical on every screen.
class WorldConfig {
  static const double width = 360;
  static const double height = 640;

  /// Placement grid. Objects snap to cell centres so solutions never depend on
  /// pixel-perfect positioning.
  static const double cell = 40;
  static const int cols = 9; // width / cell
  static const int rows = 16; // height / cell

  static const double ballRadius = 9;
  static const double defaultGravity = 380; // world units / s^2
}

/// Physical constants and per-object tuning. Central so behaviour is
/// consistent and deterministic between runs.
class Physics {
  static const double fixedDt = 1 / 120; // deterministic sub-step
  static const double restitution = 0.86; // bounciness on pegs/walls
  static const double wallRestitution = 0.72;
  static const double airDrag = 0.004; // gentle so speeds stay bounded
  static const double maxSpeed = 820;

  static const double pegRadius = 14;
  static const double springRadius = 18;
  static const double magnetRadius = 15;
  static const double magnetInfluence = 96;
  static const double magnetMinDist = 16; // clamp so force can't explode
  static const double magnetStrength = 820000;
  static const double prismRadius = 15;
  static const double teleporterRadius = 18;
  static const double crystalRadius = 16;
  static const double portalRadius = 26; // visual radius
  // Generous capture radius so success never depends on pixel-perfect aim.
  static const double portalCapture = 46;

  static const double boosterHalf = 20; // half-size of the square pad
  static const double boosterAccel = 1500;

  static const double springPower = 430;
  static const double prismSpeed = 340; // redirected speed floor

  static const double settleSpeed = 12; // below this for a while => stuck
  static const double settleTime = 1.6; // seconds ball may idle before fail
  static const double maxSimTime = 30; // hard cap
}

/// Default radius/half-extent used to test overlap for placement collisions.
double footprintRadius(ObjectType type) {
  switch (type) {
    case ObjectType.peg:
      return Physics.pegRadius;
    case ObjectType.spring:
      return Physics.springRadius;
    case ObjectType.magnet:
      return Physics.magnetRadius;
    case ObjectType.prism:
      return Physics.prismRadius;
    case ObjectType.teleporter:
      return Physics.teleporterRadius;
    case ObjectType.booster:
      return Physics.boosterHalf;
    case ObjectType.crystal:
      return Physics.crystalRadius;
    case ObjectType.portal:
      return Physics.portalRadius;
    case ObjectType.start:
      return WorldConfig.ballRadius;
    case ObjectType.wall:
      return 20;
  }
}
