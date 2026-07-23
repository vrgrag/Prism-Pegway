/// All object kinds understood by the physics engine and the editor.
enum ObjectType {
  peg,
  booster,
  spring,
  magnet,
  prism,
  teleporter,
  crystal,
  portal,
  start,
  wall,
}

/// The subset of object kinds a player can pick up, place, rotate and remove.
const List<ObjectType> placeableTypes = [
  ObjectType.peg,
  ObjectType.booster,
  ObjectType.spring,
  ObjectType.magnet,
  ObjectType.prism,
  ObjectType.teleporter,
];

extension ObjectTypeInfo on ObjectType {
  String get id => name;

  String get label {
    switch (this) {
      case ObjectType.peg:
        return 'Peg';
      case ObjectType.booster:
        return 'Booster';
      case ObjectType.spring:
        return 'Spring';
      case ObjectType.magnet:
        return 'Magnet';
      case ObjectType.prism:
        return 'Prism';
      case ObjectType.teleporter:
        return 'Teleporter';
      case ObjectType.crystal:
        return 'Crystal';
      case ObjectType.portal:
        return 'Portal';
      case ObjectType.start:
        return 'Start';
      case ObjectType.wall:
        return 'Wall';
    }
  }

  String get description {
    switch (this) {
      case ObjectType.peg:
        return 'Bounces the ball. The bread and butter of every route.';
      case ObjectType.booster:
        return 'Pushes the ball while it passes over the pad.';
      case ObjectType.spring:
        return 'Fires the ball with a strong impulse in one direction.';
      case ObjectType.magnet:
        return 'Pulls the ball, bending its path as it flies past.';
      case ObjectType.prism:
        return 'Instantly redirects the ball along a fixed beam.';
      case ObjectType.teleporter:
        return 'Warps the ball to its linked twin, keeping momentum.';
      case ObjectType.crystal:
        return 'Collect them all before entering the portal.';
      case ObjectType.portal:
        return 'The exit. Reach it with every crystal collected.';
      case ObjectType.start:
        return 'Where the ball is released.';
      case ObjectType.wall:
        return 'Solid obstacle the ball cannot pass.';
    }
  }

  bool get isDirectional =>
      this == ObjectType.booster ||
      this == ObjectType.spring ||
      this == ObjectType.prism;
}

/// A single object living in a level: either fixed by design or placed by the
/// player. Serialisable to/from a compact map for saving custom layouts.
class GameObject {
  ObjectType type;
  double x;
  double y;

  /// Facing angle in degrees (0 = up). Only meaningful for directional types.
  double angle;

  /// Sprite variant index within that type's sprite sheet.
  int variant;

  /// For teleporters: pairs objects that share the same link id.
  int link;

  /// Half-size for rectangular objects (walls). Ignored for round objects.
  double halfWidth;
  double halfHeight;

  GameObject({
    required this.type,
    required this.x,
    required this.y,
    this.angle = 0,
    this.variant = 0,
    this.link = 0,
    this.halfWidth = 20,
    this.halfHeight = 20,
  });

  GameObject clone() => GameObject(
    type: type,
    x: x,
    y: y,
    angle: angle,
    variant: variant,
    link: link,
    halfWidth: halfWidth,
    halfHeight: halfHeight,
  );

  Map<String, dynamic> toJson() => {
    't': type.index,
    'x': x,
    'y': y,
    if (angle != 0) 'a': angle,
    if (variant != 0) 'v': variant,
    if (link != 0) 'l': link,
    if (type == ObjectType.wall) 'hw': halfWidth,
    if (type == ObjectType.wall) 'hh': halfHeight,
  };

  factory GameObject.fromJson(Map<String, dynamic> j) => GameObject(
    type: ObjectType.values[j['t'] as int],
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    angle: (j['a'] as num?)?.toDouble() ?? 0,
    variant: (j['v'] as num?)?.toInt() ?? 0,
    link: (j['l'] as num?)?.toInt() ?? 0,
    halfWidth: (j['hw'] as num?)?.toDouble() ?? 20,
    halfHeight: (j['hh'] as num?)?.toDouble() ?? 20,
  );
}
