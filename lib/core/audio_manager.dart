import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Named SFX -> asset file (under assets/audio/).
class Sfx {
  static const String complete = 'sfx_complete';
  static const String fail = 'sfx_fail';
  static const String crystal = 'sfx_crystal';
  static const String bounce = 'sfx_bounce';
  static const String booster = 'sfx_booster';
  static const String spring = 'sfx_spring';
  static const String magnet = 'sfx_magnet';
  static const String prism = 'sfx_prism';
  static const String teleport = 'sfx_teleport';
  static const String portal = 'sfx_portal';
  static const String click = 'sfx_click';
  static const String place = 'sfx_place';
  static const String launch = 'sfx_launch';
  static const String combo = 'sfx_combo';
  static const String reward = 'sfx_reward';
  static const String unlock = 'sfx_unlock';

  /// File extension every SFX/music asset is stored with.
  static const String ext = 'mp3';
}

enum MusicTrack { none, menu, gameplay }

/// Handles looping music (single instance, never doubled) and pooled one-shot
/// SFX. Every playback is wrapped in try/catch so absent audio files (the repo
/// ships without binaries) never crash or spam the app.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  // Players are created lazily in [init] so simply referencing the singleton
  // (e.g. to read/apply settings) never touches platform channels — important
  // for unit tests and for the pre-init window during boot.
  AudioPlayer? _music;
  List<AudioPlayer> _sfxPool = const [];
  int _sfxIndex = 0;

  bool musicEnabled = true;
  bool soundEnabled = true;
  double musicVolume = 0.6;
  double effectsVolume = 0.85;

  MusicTrack _current = MusicTrack.none;
  bool _initialised = false;
  final Set<String> _knownMissing = {};

  /// Disabled under unit tests (no audio plugin / platform channels).
  static final bool _disabled =
      Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> init() async {
    if (_disabled || _initialised) return;
    _initialised = true;
    try {
      _music = AudioPlayer(playerId: 'prism_music');
      _sfxPool =
          List.generate(6, (i) => AudioPlayer(playerId: 'prism_sfx_$i'));
      await _music!.setReleaseMode(ReleaseMode.loop);
      for (final p in _sfxPool) {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
      }
      _music!.setVolume(musicEnabled ? musicVolume : 0).catchError((_) {});
    } catch (_) {}
  }

  void applySettings({
    required bool music,
    required bool sound,
    required double musicVol,
    required double effectsVol,
  }) {
    musicEnabled = music;
    soundEnabled = sound;
    musicVolume = musicVol;
    effectsVolume = effectsVol;
    final player = _music;
    if (_disabled || player == null) return;
    player.setVolume(musicEnabled ? musicVolume : 0).catchError((_) {});
    if (!musicEnabled) {
      player.pause().catchError((_) {});
    } else if (_current != MusicTrack.none) {
      player.resume().catchError((_) {});
    }
  }

  Future<void> playMusic(MusicTrack track) async {
    final music = _music;
    if (_disabled || music == null) return;
    if (track == _current) return;
    _current = track;
    if (track == MusicTrack.none) {
      await music.stop().catchError((_) {});
      return;
    }
    if (!musicEnabled) return;
    final file = track == MusicTrack.menu ? 'music_menu' : 'music_gameplay';
    if (_knownMissing.contains(file)) return;
    try {
      await music.stop();
      await music.setVolume(musicVolume);
      await music.play(AssetSource('audio/$file.${Sfx.ext}'));
    } catch (e) {
      _knownMissing.add(file);
      if (kDebugMode) debugPrint('Music asset missing: $file ($e)');
    }
  }

  void playSfx(String name) {
    if (_disabled || !soundEnabled || _sfxPool.isEmpty) return;
    if (_knownMissing.contains(name)) return;
    final player = _sfxPool[_sfxIndex];
    _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;
    player
        .play(AssetSource('audio/$name.${Sfx.ext}'), volume: effectsVolume)
        .catchError((Object e) {
          _knownMissing.add(name);
        });
  }

  Future<void> pauseMusic() async {
    await _music?.pause().catchError((_) {});
  }

  Future<void> resumeMusic() async {
    if (musicEnabled && _current != MusicTrack.none) {
      await _music?.resume().catchError((_) {});
    }
  }

  Future<void> dispose() async {
    await _music?.dispose().catchError((_) {});
    for (final p in _sfxPool) {
      await p.dispose().catchError((_) {});
    }
  }
}
