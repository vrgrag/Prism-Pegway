class GameSettings {
  bool musicOn;
  bool soundOn;
  bool hapticsOn;
  double musicVolume;
  double effectsVolume;

  GameSettings({
    this.musicOn = true,
    this.soundOn = true,
    this.hapticsOn = true,
    this.musicVolume = 0.6,
    this.effectsVolume = 0.85,
  });

  Map<String, dynamic> toJson() => {
    'musicOn': musicOn,
    'soundOn': soundOn,
    'hapticsOn': hapticsOn,
    'musicVolume': musicVolume,
    'effectsVolume': effectsVolume,
  };

  factory GameSettings.fromJson(Map<String, dynamic> j) => GameSettings(
    musicOn: j['musicOn'] as bool? ?? true,
    soundOn: j['soundOn'] as bool? ?? true,
    hapticsOn: j['hapticsOn'] as bool? ?? true,
    musicVolume: (j['musicVolume'] as num?)?.toDouble() ?? 0.6,
    effectsVolume: (j['effectsVolume'] as num?)?.toDouble() ?? 0.85,
  );
}
