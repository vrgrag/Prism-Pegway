import 'dart:math';

/// Short, non-intrusive encouraging messages (English only).
class Messages {
  static final Random _rng = Random();

  static String _pick(List<String> list) => list[_rng.nextInt(list.length)];

  static String win(int stars) {
    if (stars >= 3) {
      return _pick(const [
        'Perfect trajectory!',
        'Brilliant chain!',
        'Flawless engineering!',
        'Absolutely optimal!',
      ]);
    }
    return _pick(const [
      'Portal reached!',
      'Nice routing!',
      'Energy delivered!',
      'Well built!',
    ]);
  }

  static String fail(int crystals, int total) {
    if (total > 0 && crystals >= total - 1 && crystals < total) {
      return _pick(const ['So close!', 'Almost had it!', 'One crystal short!']);
    }
    return _pick(const [
      'Try a sharper angle.',
      'Rethink the path.',
      'Adjust and launch again.',
      'A booster might help here.',
    ]);
  }

  static const String newSkin = 'New skin unlocked!';
  static const String newComponent = 'New component unlocked!';
}
