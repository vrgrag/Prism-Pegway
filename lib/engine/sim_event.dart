enum SimEventType {
  bounce,
  wall,
  booster,
  spring,
  magnet,
  prism,
  teleport,
  crystal,
  win,
  fail,
}

/// A discrete event produced by the physics step, consumed by the render layer
/// to trigger sounds, haptics and particle effects.
class SimEvent {
  final SimEventType type;
  final double x;
  final double y;
  const SimEvent(this.type, this.x, this.y);
}

/// The outcome of a headless simulation run.
class SimResult {
  final bool won;
  final bool timedOut;
  final int crystalsCollected;
  final int totalCrystals;
  final double time;

  const SimResult({
    required this.won,
    required this.timedOut,
    required this.crystalsCollected,
    required this.totalCrystals,
    required this.time,
  });

  bool get allCrystalsCollected => crystalsCollected >= totalCrystals;
}
