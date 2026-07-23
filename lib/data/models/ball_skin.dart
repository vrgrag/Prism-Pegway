/// A ball skin definition. Sprite `index` maps to assets/sprites/skins/N.png.
class BallSkin {
  final int index;
  final String id;
  final String name;

  /// Total stars required to unlock (0 = free). Ignored when [dailyReward].
  final int starsRequired;

  /// If true, this skin is unlocked as a daily-challenge reward instead.
  final bool dailyReward;

  const BallSkin({
    required this.index,
    required this.id,
    required this.name,
    this.starsRequired = 0,
    this.dailyReward = false,
  });

  String get asset => 'assets/sprites/skins/$index.png';
}

const List<BallSkin> kBallSkins = [
  BallSkin(index: 0, id: 'prism', name: 'Prism Core', starsRequired: 0),
  BallSkin(index: 1, id: 'pulsar', name: 'Pulsar', starsRequired: 6),
  BallSkin(index: 2, id: 'cryo', name: 'Cryo Cell', starsRequired: 15),
  BallSkin(index: 3, id: 'nebula', name: 'Nebula', starsRequired: 28),
  BallSkin(index: 4, id: 'plasma', name: 'Plasma', starsRequired: 45),
  BallSkin(index: 5, id: 'vortex', name: 'Vortex', dailyReward: true),
  BallSkin(index: 6, id: 'disco', name: 'Disco Grid', starsRequired: 70),
  BallSkin(index: 7, id: 'starburst', name: 'Starburst', starsRequired: 95),
];

BallSkin skinById(String id) =>
    kBallSkins.firstWhere((s) => s.id == id, orElse: () => kBallSkins.first);
