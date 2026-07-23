import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/audio_manager.dart';
import '../../core/haptics.dart';
import '../../core/messages.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../data/level_library.dart';
import '../../data/models/attempt_result.dart';
import '../../data/models/ball_skin.dart';
import '../../engine/config.dart';
import '../../engine/game_object.dart';
import '../../engine/level.dart';
import '../../game/game_controller.dart';
import '../../game/prism_game.dart';
import '../nav.dart';
import '../overlays/game_overlays.dart';
import '../widgets/neon_button.dart';
import 'how_to_play_screen.dart';

class GameplayScreen extends StatefulWidget {
  final int levelId;
  const GameplayScreen({super.key, required this.levelId});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with WidgetsBindingObserver {
  final GlobalKey _fieldKey = GlobalKey();
  late LevelData level;
  late GameController controller;
  late PrismGame game;

  bool _paused = false;
  GamePhase _lastPhase = GamePhase.editing;
  String _message = '';
  List<BallSkin> _newSkins = const [];
  Size _fieldSize = const Size(360, 640);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    level = levelById(widget.levelId);
    controller = GameController(level);
    final state = GameStateScope.read(context);
    final skin = skinById(state.selectedSkin);
    game = PrismGame(
      controller: controller,
      skinAsset: Sprites.skin(skin.index),
    );
    controller.addListener(_onControllerChanged);
    AudioManager.instance.playMusic(MusicTrack.gameplay);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    AudioManager.instance.playMusic(MusicTrack.menu);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _pauseGame();
      AudioManager.instance.pauseMusic();
    } else if (!_paused) {
      AudioManager.instance.resumeMusic();
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (controller.phase != _lastPhase) {
      if (controller.phase == GamePhase.won ||
          controller.phase == GamePhase.failed) {
        _resolveAttempt();
      }
      _lastPhase = controller.phase;
    }
    setState(() {});
  }

  void _resolveAttempt() {
    final state = GameStateScope.read(context);
    final w = controller.world;
    final crystals = w?.crystalsCollected ?? 0;
    final won = controller.phase == GamePhase.won;
    final result = AttemptResult(
      levelId: level.id,
      won: won,
      crystalsCollected: crystals,
      totalCrystals: level.crystals.length,
      objectsUsed: controller.objectsUsed,
      par: level.par,
      time: controller.simTime,
      usedBoosters: controller.usedBoosters,
      magnetHits: controller.magnetHits,
      firstAttempt: controller.attemptsThisVisit == 1,
    );
    _newSkins = state.recordAttempt(result);
    if (won) {
      _message = Messages.win(controller.finalStars);
      AudioManager.instance.playSfx(Sfx.portal);
    } else {
      _message = Messages.fail(crystals, level.crystals.length);
    }
    if (_newSkins.isNotEmpty) {
      _message = '$_message  ${Messages.newSkin}';
      AudioManager.instance.playSfx(Sfx.unlock);
    }
  }

  // --- Interaction helpers ----------------------------------------------------

  Vector2 _localToWorld(Offset local) => Vector2(
    (local.dx / _fieldSize.width * WorldConfig.width).clamp(
      0,
      WorldConfig.width,
    ),
    (local.dy / _fieldSize.height * WorldConfig.height).clamp(
      0,
      WorldConfig.height,
    ),
  );

  Offset? _globalToLocal(Offset global) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(global);
  }

  void _onTapDown(TapDownDetails d) {
    if (!controller.isEditing) return;
    final world = _localToWorld(d.localPosition);
    final hit = controller.objectAt(world.x, world.y);
    if (hit != null) {
      controller.selectObject(
        identical(hit, controller.selectedObject) ? null : hit,
      );
      Haptics.selection();
      return;
    }
    final tool = controller.selectedTool;
    if (tool != null && controller.canPlaceAt(tool, world.x, world.y)) {
      if (controller.placeAt(tool, world.x, world.y)) {
        AudioManager.instance.playSfx(Sfx.place);
        Haptics.light();
      }
    } else {
      controller.selectObject(null);
    }
  }

  void _onPanStart(DragStartDetails d) {
    if (!controller.isEditing) return;
    final world = _localToWorld(d.localPosition);
    final hit = controller.objectAt(world.x, world.y);
    if (hit != null) controller.selectObject(hit);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!controller.isEditing || controller.selectedObject == null) return;
    final world = _localToWorld(d.localPosition);
    controller.moveSelected(world.x, world.y);
  }

  // --- Actions ----------------------------------------------------------------

  void _launch() {
    if (!controller.isEditing) return;
    AudioManager.instance.playSfx(Sfx.launch);
    Haptics.medium();
    controller.launch();
  }

  void _pauseGame() {
    if (_paused) return;
    setState(() => _paused = true);
    game.simPaused = true;
  }

  void _resume() {
    setState(() => _paused = false);
    game.simPaused = false;
    AudioManager.instance.resumeMusic();
  }

  void _restart() {
    controller.backToEdit();
    setState(() {
      _paused = false;
      _lastPhase = GamePhase.editing;
    });
    game.simPaused = false;
  }

  void _editRetry() {
    controller.backToEdit();
    setState(() => _lastPhase = GamePhase.editing);
  }

  void _goMenu() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _next() {
    final nextId = level.id + 1;
    if (nextId > kLevels.length) {
      _goMenu();
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(prismRoute(GameplayScreen(levelId: nextId)));
  }

  Future<void> _handleBack() async {
    if (_paused) {
      _resume();
      return;
    }
    if (controller.phase == GamePhase.won ||
        controller.phase == GamePhase.failed) {
      _editRetry();
      return;
    }
    if (controller.isSimulating) {
      _restart();
      return;
    }
    Navigator.of(context).pop();
  }

  // --- Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                Sprites.background(level.backgroundIndex),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: PrismColors.bg0),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHud(),
                  Expanded(child: Center(child: _buildField())),
                  _buildBottom(),
                ],
              ),
            ),
            if (_paused)
              PauseOverlay(
                onResume: _resume,
                onRestart: _restart,
                onHowToPlay: () => Navigator.of(
                  context,
                ).push(prismRoute(const HowToPlayScreen())),
                onMenu: _goMenu,
              ),
            if (!_paused && controller.phase == GamePhase.won) _buildComplete(),
            if (!_paused && controller.phase == GamePhase.failed)
              LevelFailedOverlay(
                crystals: controller.world?.crystalsCollected ?? 0,
                totalCrystals: level.crystals.length,
                message: _message,
                onEdit: _editRetry,
                onMenu: _goMenu,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete() {
    final state = GameStateScope.read(context);
    final lp = state.progressFor(level.id);
    return LevelCompleteOverlay(
      stars: controller.finalStars,
      score: controller.finalScore,
      bestScore: lp.bestScore,
      crystals: controller.world?.crystalsCollected ?? 0,
      totalCrystals: level.crystals.length,
      objectsUsed: controller.objectsUsed,
      message: _message,
      hasNext: level.id < kLevels.length,
      onNext: _next,
      onRetry: _editRetry,
      onMenu: _goMenu,
    );
  }

  Widget _buildHud() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          NeonIconButton(
            icon: Icons.pause_rounded,
            onTap: _pauseGame,
            color: PrismColors.cyan,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${level.id}',
                  style: PrismText.label(13, color: PrismColors.cyan),
                ),
                Text(
                  level.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PrismText.title(18),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: game.frame,
            builder: (context, _, __) => _HudChip(
              icon: Icons.diamond_rounded,
              color: PrismColors.magenta,
              text:
                  '${controller.world?.crystalsCollected ?? 0}/${level.crystals.length}',
            ),
          ),
          const SizedBox(width: 8),
          _HudChip(
            icon: Icons.widgets_rounded,
            color: PrismColors.amber,
            text: '${controller.objectsUsed}',
          ),
        ],
      ),
    );
  }

  Widget _buildField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fit a 9:16 field within the available area.
        var w = constraints.maxWidth;
        var h = w * WorldConfig.height / WorldConfig.width;
        if (h > constraints.maxHeight) {
          h = constraints.maxHeight;
          w = h * WorldConfig.width / WorldConfig.height;
        }
        _fieldSize = Size(w, h);
        return Container(
          key: _fieldKey,
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: PrismColors.violet.withValues(alpha: 0.5),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: PrismColors.violet.withValues(alpha: 0.35),
                blurRadius: 22,
                spreadRadius: -6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                Positioned.fill(child: GameWidget(game: game)),
                Positioned.fill(
                  child: DragTarget<ObjectType>(
                    onWillAcceptWithDetails: (d) =>
                        controller.isEditing &&
                        (controller.remaining[d.data] ?? 0) > 0,
                    onMove: (d) {
                      final local = _globalToLocal(d.offset);
                      if (local == null) return;
                      final wpos = _localToWorld(local);
                      setState(() {
                        game.ghostTool = d.data;
                        game.ghostPos = wpos;
                        game.ghostValid = controller.canPlaceAt(
                          d.data,
                          wpos.x,
                          wpos.y,
                        );
                      });
                    },
                    onLeave: (_) => setState(() {
                      game.ghostTool = null;
                      game.ghostPos = null;
                    }),
                    onAcceptWithDetails: (d) {
                      final local = _globalToLocal(d.offset);
                      game.ghostTool = null;
                      game.ghostPos = null;
                      if (local == null) return;
                      final wpos = _localToWorld(local);
                      if (controller.placeAt(d.data, wpos.x, wpos.y)) {
                        AudioManager.instance.playSfx(Sfx.place);
                        Haptics.light();
                      }
                    },
                    builder: (context, _, __) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _onTapDown,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottom() {
    if (!controller.isEditing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, color: PrismColors.cyan),
            const SizedBox(width: 8),
            Text('Simulating…', style: PrismText.label(16)),
            const SizedBox(width: 16),
            NeonIconButton(
              icon: Icons.replay_rounded,
              onTap: _restart,
              color: PrismColors.magenta,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.selectedObject != null) _buildSelectedControls(),
          _buildInventory(),
          const SizedBox(height: 10),
          Row(
            children: [
              NeonIconButton(
                icon: Icons.lightbulb_outline_rounded,
                color: PrismColors.amber,
                tooltip: 'Hint',
                onTap: () {
                  if (!controller.applyHint()) Haptics.medium();
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonButton(
                  label: 'Launch',
                  icon: Icons.rocket_launch_rounded,
                  onTap: _launch,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedControls() {
    final obj = controller.selectedObject!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (obj.type.isDirectional) ...[
            NeonIconButton(
              icon: Icons.rotate_right_rounded,
              onTap: () {
                controller.rotateSelected();
                Haptics.selection();
              },
              color: PrismColors.cyan,
            ),
            const SizedBox(width: 14),
          ],
          NeonIconButton(
            icon: Icons.delete_outline_rounded,
            onTap: () {
              controller.removeSelected();
              Haptics.medium();
            },
            color: PrismColors.magenta,
          ),
          const SizedBox(width: 14),
          Text(obj.type.label, style: PrismText.label(14)),
        ],
      ),
    );
  }

  Widget _buildInventory() {
    final entries = level.inventory.keys.toList();
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final type = entries[i];
          final count = controller.remaining[type] ?? 0;
          final selected = controller.selectedTool == type;
          final chip = _InventoryChip(
            type: type,
            count: count,
            selected: selected,
            onTap: () => controller.selectTool(type),
          );
          if (count == 0) return chip;
          return Draggable<ObjectType>(
            data: type,
            feedback: _DragFeedback(type: type),
            childWhenDragging: Opacity(opacity: 0.4, child: chip),
            child: chip,
          );
        },
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _HudChip({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PrismColors.bg1.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(text, style: PrismText.label(14)),
        ],
      ),
    );
  }
}

class _InventoryChip extends StatelessWidget {
  final ObjectType type;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _InventoryChip({
    required this.type,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = count == 0;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Container(
          width: 66,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: PrismColors.bg1.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? PrismColors.cyan : PrismColors.panelBorder,
              width: selected ? 2 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: PrismColors.cyan.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    Sprites.forType(type),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.circle, size: 40),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: PrismColors.magenta,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: PrismText.label(11, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PrismText.body(9, color: PrismColors.textLo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  final ObjectType type;
  const _DragFeedback({required this.type});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Sprites.forType(type),
      width: 52,
      height: 52,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 52),
    );
  }
}
