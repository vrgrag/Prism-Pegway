import '../engine/game_object.dart';

/// Central registry of the sliced sprite assets and how many variants each has.
class Sprites {
  static const String logo = 'assets/Game_Name.webp';
  static const String icon = 'assets/Icon.png';
  static const String loadingPortrait = 'assets/Vertical_Loading_Screen.webp';
  static const String loadingLandscape =
      'assets/Horizontal_Loading_Screen.webp';

  static const int backgroundCount = 8;
  static String background(int index) =>
      'assets/bg_location_${index.clamp(1, backgroundCount)}_asset.webp';

  static const Map<String, int> counts = {
    'pegs': 12,
    'skins': 8,
    'crystals': 15,
    'prisms': 12,
    'boosters': 10,
    'springs': 8,
    'magnets': 8,
    'teleporters': 8,
    'markers': 10,
  };

  static String skin(int index) => 'assets/sprites/skins/$index.png';
  static String crystal(int index) => 'assets/sprites/crystals/$index.png';
  static String marker(int index) => 'assets/sprites/markers/$index.png';

  static String _folder(ObjectType type) {
    switch (type) {
      case ObjectType.peg:
        return 'pegs';
      case ObjectType.booster:
        return 'boosters';
      case ObjectType.spring:
        return 'springs';
      case ObjectType.magnet:
        return 'magnets';
      case ObjectType.prism:
        return 'prisms';
      case ObjectType.teleporter:
      case ObjectType.portal:
        return 'teleporters';
      case ObjectType.crystal:
        return 'crystals';
      case ObjectType.start:
      case ObjectType.wall:
        return 'markers';
    }
  }

  /// Asset path for an object type + variant, clamped to the sheet's range.
  static String forType(ObjectType type, [int variant = 0]) {
    final folder = _folder(type);
    final max = counts[folder] ?? 1;
    final v = variant % max;
    return 'assets/sprites/$folder/$v.png';
  }

  /// Every asset that should be pre-warmed during the loading screen.
  static List<String> preloadList() {
    final list = <String>[logo];
    for (var i = 1; i <= backgroundCount; i++) {
      list.add(background(i));
    }
    for (final entry in counts.entries) {
      for (var i = 0; i < entry.value; i++) {
        list.add('assets/sprites/${entry.key}/$i.png');
      }
    }
    return list;
  }
}
