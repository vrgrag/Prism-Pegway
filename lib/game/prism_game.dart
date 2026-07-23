import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;

import '../core/audio_manager.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../engine/config.dart';
import '../engine/game_object.dart';
import '../engine/sim_event.dart';
import 'game_controller.dart';

/// Flame game that renders the playfield and steps the deterministic engine
/// during a simulation. All physics live in [GameController]/PhysicsWorld; this
/// class is purely presentation + event feedback.
class PrismGame extends FlameGame {
  final GameController controller;
  String skinAsset;
  final void Function()? onResolved;

  PrismGame({
    required this.controller,
    required this.skinAsset,
    this.onResolved,
  }) : super(
         camera: CameraComponent.withFixedResolution(
           width: WorldConfig.width,
           height: WorldConfig.height,
         ),
       );

  final Map<String, Sprite> _sprites = {};
  final List<_Particle> _particles = [];
  final List<Offset> _trail = [];
  final Map<String, double> _sfxThrottle = {};
  bool _resolvedSent = false;

  /// Pauses the simulation stepping (app backgrounded / pause overlay).
  bool simPaused = false;

  /// Ticks every rendered frame so the Flutter HUD can cheaply read live
  /// simulation values (crystals, time) via a ValueListenableBuilder.
  final ValueNotifier<int> frame = ValueNotifier<int>(0);

  // Placement ghost, set by the gameplay screen during drag.
  ObjectType? ghostTool;
  Vector2? ghostPos;
  bool ghostValid = false;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    await _loadSprites();
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2(WorldConfig.width / 2, WorldConfig.height / 2);
    world.add(_FieldComponent(this));
  }

  Future<void> _load(String key, String path) async {
    if (_sprites.containsKey(key)) return;
    final img = await images.load(path);
    _sprites[key] = Sprite(img);
  }

  Future<void> _loadSprites() async {
    await _load('peg', 'sprites/pegs/0.png');
    await _load('booster', 'sprites/boosters/0.png');
    await _load('spring', 'sprites/springs/0.png');
    await _load('magnet', 'sprites/magnets/0.png');
    await _load('prism', 'sprites/prisms/0.png');
    await _load('teleporter', 'sprites/teleporters/0.png');
    await _load('portal', 'sprites/teleporters/1.png');
    await _load('start', 'sprites/markers/0.png');
    await _load('wall', 'sprites/markers/6.png');
    for (var i = 0; i < 15; i++) {
      await _load('crystal$i', 'sprites/crystals/$i.png');
    }
    final skinPath = skinAsset.replaceFirst('assets/', '');
    await _load('ball', skinPath);
  }

  Future<void> setSkin(String assetPath) async {
    skinAsset = assetPath;
    final path = assetPath.replaceFirst('assets/', '');
    final img = await images.load(path);
    _sprites['ball'] = Sprite(img);
  }

  Sprite? spriteFor(ObjectType type) {
    switch (type) {
      case ObjectType.peg:
        return _sprites['peg'];
      case ObjectType.booster:
        return _sprites['booster'];
      case ObjectType.spring:
        return _sprites['spring'];
      case ObjectType.magnet:
        return _sprites['magnet'];
      case ObjectType.prism:
        return _sprites['prism'];
      case ObjectType.teleporter:
        return _sprites['teleporter'];
      case ObjectType.portal:
        return _sprites['portal'];
      case ObjectType.start:
        return _sprites['start'];
      case ObjectType.wall:
        return _sprites['wall'];
      case ObjectType.crystal:
        return _sprites['crystal0'];
    }
  }

  Sprite? crystalSprite(int i) => _sprites['crystal${i % 15}'];
  Sprite? get ballSprite => _sprites['ball'];

  @override
  void update(double dt) {
    super.update(dt);
    frame.value++;
    _updateParticles(dt);
    final w = controller.world;
    if (controller.isSimulating && !simPaused && w != null) {
      w.advance(dt);
      controller.simTime = w.time;
      _drainEvents();
      _trail.add(Offset(w.ballPos.x, w.ballPos.y));
      if (_trail.length > 18) _trail.removeAt(0);
      if (w.finished && !_resolvedSent) {
        _resolvedSent = true;
        controller.onSimResolved();
        onResolved?.call();
      }
    } else {
      _resolvedSent = false;
      if (!controller.isSimulating) _trail.clear();
    }
  }

  void _drainEvents() {
    final w = controller.world;
    if (w == null) return;
    for (final e in w.events) {
      switch (e.type) {
        case SimEventType.bounce:
        case SimEventType.wall:
          _throttledSfx(Sfx.bounce, 0.06);
          _burst(e.x, e.y, PrismColors.cyan, 3);
          break;
        case SimEventType.crystal:
          if (w.totalCrystals > 1 && w.crystalsCollected == w.totalCrystals) {
            AudioManager.instance.playSfx(Sfx.combo);
          } else {
            AudioManager.instance.playSfx(Sfx.crystal);
          }
          Haptics.light();
          _burst(e.x, e.y, PrismColors.magenta, 10);
          break;
        case SimEventType.booster:
          controller.noteBoosterUsed();
          _throttledSfx(Sfx.booster, 0.2);
          _burst(e.x, e.y, PrismColors.blue, 2);
          break;
        case SimEventType.spring:
          AudioManager.instance.playSfx(Sfx.spring);
          Haptics.light();
          _burst(e.x, e.y, PrismColors.green, 8);
          break;
        case SimEventType.magnet:
          controller.noteMagnetTriggered(_key(e.x, e.y));
          _throttledSfx(Sfx.magnet, 0.3);
          break;
        case SimEventType.prism:
          AudioManager.instance.playSfx(Sfx.prism);
          _burst(e.x, e.y, PrismColors.violet, 8);
          break;
        case SimEventType.teleport:
          AudioManager.instance.playSfx(Sfx.teleport);
          Haptics.light();
          _burst(e.x, e.y, PrismColors.cyan, 12);
          break;
        case SimEventType.win:
          AudioManager.instance.playSfx(Sfx.complete);
          Haptics.success();
          _burst(e.x, e.y, PrismColors.amber, 26);
          break;
        case SimEventType.fail:
          AudioManager.instance.playSfx(Sfx.fail);
          break;
      }
    }
    w.events.clear();
  }

  int _key(double x, double y) => (x.round() * 1000 + y.round());

  void _throttledSfx(String name, double minGap) {
    final now = controller.simTime;
    final last = _sfxThrottle[name] ?? -999;
    if (now - last >= minGap) {
      _sfxThrottle[name] = now;
      AudioManager.instance.playSfx(name);
    }
  }

  void _burst(double x, double y, Color color, int count) {
    final rng = math.Random();
    for (var i = 0; i < count; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final sp = 20 + rng.nextDouble() * 90;
      _particles.add(
        _Particle(
          Offset(x, y),
          Offset(math.cos(a) * sp, math.sin(a) * sp),
          color,
          0.4 + rng.nextDouble() * 0.4,
          1.5 + rng.nextDouble() * 2.5,
        ),
      );
    }
  }

  void _updateParticles(double dt) {
    for (final p in _particles) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel *= 0.92;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }
}

class _Particle {
  Offset pos;
  Offset vel;
  final Color color;
  double life;
  final double maxLife;
  final double radius;
  _Particle(this.pos, this.vel, this.color, this.life, this.radius)
    : maxLife = life;
}

/// Draws the whole playfield in world coordinates (0..360 x 0..640).
class _FieldComponent extends PositionComponent {
  final PrismGame game;
  _FieldComponent(this.game);

  @override
  void render(Canvas canvas) {
    final c = game.controller;
    final level = c.level;

    // Field frame.
    final frame = Rect.fromLTWH(0, 0, WorldConfig.width, WorldConfig.height);
    canvas.drawRect(frame, Paint()..color = const Color(0x22000000));
    canvas.drawRect(
      frame.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = PrismColors.violet.withValues(alpha: 0.4),
    );

    if (c.isEditing) _drawGrid(canvas);

    _drawMarker(
      canvas,
      game.spriteFor(ObjectType.start),
      level.startX,
      level.startY,
      40,
    );
    _drawPortal(canvas, level.portalX, level.portalY);

    // Crystals.
    for (var i = 0; i < level.crystals.length; i++) {
      final cr = level.crystals[i];
      final collected = c.world?.crystalCollected(i) ?? false;
      if (collected) continue;
      final s = game.crystalSprite(i * 3 + 2);
      _pulse(canvas, cr.x, cr.y);
      _drawSprite(canvas, s, cr.x, cr.y, 30, 0);
    }

    // Fixed objects.
    for (final o in level.fixedObjects) {
      _drawObject(canvas, o, fixed: true);
    }

    // Player objects.
    for (final o in c.playerObjects) {
      final selected = identical(o, c.selectedObject);
      if (selected) {
        canvas.drawCircle(
          Offset(o.x, o.y),
          24,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = PrismColors.cyan,
        );
      }
      _drawObject(canvas, o, fixed: false);
    }

    // Placement ghost.
    if (c.isEditing && game.ghostTool != null && game.ghostPos != null) {
      final gx = GameController.snap(game.ghostPos!.x);
      final gy = GameController.snap(game.ghostPos!.y);
      final color = game.ghostValid ? PrismColors.green : PrismColors.magenta;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(gx, gy),
            width: WorldConfig.cell,
            height: WorldConfig.cell,
          ),
          const Radius.circular(8),
        ),
        Paint()..color = color.withValues(alpha: 0.25),
      );
      final s = game.spriteFor(game.ghostTool!);
      _drawSprite(
        canvas,
        s,
        gx,
        gy,
        _sizeFor(game.ghostTool!),
        0,
        opacity: 0.7,
      );
    }

    // Ball trail + ball.
    final w = c.world;
    if (c.isSimulating && w != null) {
      _drawTrail(canvas);
      _drawSprite(
        canvas,
        game.ballSprite,
        w.ballPos.x,
        w.ballPos.y,
        WorldConfig.ballRadius * 2.6,
        0,
      );
    }

    // Particles.
    for (final p in game._particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.radius,
        Paint()
          ..color = p.color.withValues(alpha: a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= WorldConfig.width; x += WorldConfig.cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, WorldConfig.height), paint);
    }
    for (var y = 0.0; y <= WorldConfig.height; y += WorldConfig.cell) {
      canvas.drawLine(Offset(0, y), Offset(WorldConfig.width, y), paint);
    }
  }

  void _drawTrail(Canvas canvas) {
    final trail = game._trail;
    for (var i = 0; i < trail.length; i++) {
      final a = i / trail.length;
      canvas.drawCircle(
        trail[i],
        WorldConfig.ballRadius * (0.3 + a * 0.7),
        Paint()
          ..color = PrismColors.cyan.withValues(alpha: a * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _pulse(Canvas canvas, double x, double y) {
    canvas.drawCircle(
      Offset(x, y),
      18,
      Paint()
        ..color = PrismColors.magenta.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawPortal(Canvas canvas, double x, double y) {
    final allCollected = (game.controller.world?.allCrystalsCollected) ?? false;
    final glow = allCollected ? PrismColors.green : PrismColors.violet;
    canvas.drawCircle(
      Offset(x, y),
      34,
      Paint()
        ..color = glow.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    _drawSprite(canvas, game.spriteFor(ObjectType.portal), x, y, 62, 0);
  }

  void _drawMarker(Canvas canvas, Sprite? s, double x, double y, double size) {
    _drawSprite(canvas, s, x, y, size, 0);
  }

  void _drawObject(Canvas canvas, GameObject o, {required bool fixed}) {
    if (o.type == ObjectType.wall) {
      _drawWall(canvas, o);
      return;
    }
    final size = _sizeFor(o.type);
    final angleRad = o.type.isDirectional ? o.angle * math.pi / 180 : 0.0;
    _drawSprite(canvas, game.spriteFor(o.type), o.x, o.y, size, angleRad);
    if (o.type == ObjectType.teleporter && o.link > 0) {
      // Colored ring so paired teleporters are readable at a glance.
      final ringColor = [
        PrismColors.cyan,
        PrismColors.magenta,
        PrismColors.green,
        PrismColors.amber,
      ][(o.link - 1) % 4];
      canvas.drawCircle(
        Offset(o.x, o.y),
        size * 0.42,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = ringColor,
      );
    }
  }

  void _drawWall(Canvas canvas, GameObject o) {
    final rect = Rect.fromCenter(
      center: Offset(o.x, o.y),
      width: o.halfWidth * 2,
      height: o.halfHeight * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF201D45));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = PrismColors.blue.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );
  }

  double _sizeFor(ObjectType type) {
    switch (type) {
      case ObjectType.peg:
        return 30;
      case ObjectType.booster:
        return 40;
      case ObjectType.spring:
        return 40;
      case ObjectType.magnet:
        return 36;
      case ObjectType.prism:
        return 34;
      case ObjectType.teleporter:
        return 42;
      case ObjectType.portal:
        return 62;
      case ObjectType.start:
        return 40;
      case ObjectType.wall:
        return 40;
      case ObjectType.crystal:
        return 30;
    }
  }

  void _drawSprite(
    Canvas canvas,
    Sprite? sprite,
    double x,
    double y,
    double size,
    double angleRad, {
    double opacity = 1,
  }) {
    if (sprite == null) return;
    canvas.save();
    canvas.translate(x, y);
    if (angleRad != 0) canvas.rotate(angleRad);
    final paint = Paint();
    if (opacity < 1) paint.color = Colors.white.withValues(alpha: opacity);
    sprite.render(
      canvas,
      position: Vector2(-size / 2, -size / 2),
      size: Vector2(size, size),
      overridePaint: paint,
    );
    canvas.restore();
  }
}
