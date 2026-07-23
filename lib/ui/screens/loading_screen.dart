import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/audio_manager.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../nav.dart';
import 'main_menu_screen.dart';

/// First screen. Performs real initialisation (save data, audio, image
/// pre-warming) while showing a left-to-right progress bar that only fills
/// completely once boot is actually done. Supports both portrait and landscape
/// loading art.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0;
  int _dots = 0;
  Timer? _dotTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final state = GameStateScope.read(context);

    void bump(double v) {
      if (mounted) setState(() => _progress = v.clamp(0, 0.95));
    }

    // 1. Persistent data.
    await state.saverInit();
    bump(0.12);
    await state.load();
    bump(0.25);

    // 2. Audio subsystem.
    await AudioManager.instance.init();
    bump(0.32);

    // 3. Pre-warm images so the first frames never stutter.
    final assets = Sprites.preloadList();
    for (var i = 0; i < assets.length; i++) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(assets[i]), context);
      } catch (_) {}
      bump(0.32 + 0.63 * (i + 1) / assets.length);
    }

    // Real init done -> fill the bar, then transition.
    if (!mounted) return;
    setState(() => _progress = 1);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted || _navigated) return;
    _navigated = true;
    AudioManager.instance.playMusic(MusicTrack.menu);
    Navigator.of(context).pushReplacement(prismRoute(const MainMenuScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismColors.bg0,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          final bg = isPortrait
              ? Sprites.loadingPortrait
              : Sprites.loadingLandscape;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                bg,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const DecoratedBox(
                  decoration: BoxDecoration(gradient: PrismGradients.backdrop),
                ),
              ),
              Container(color: Colors.black.withValues(alpha: 0.15)),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 36,
                    right: 36,
                    bottom: isPortrait ? 70 : 34,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProgressBar(value: _progress),
                      const SizedBox(height: 14),
                      Text(
                        'Loading${'.' * _dots}',
                        style: PrismText.label(16, color: PrismColors.textHi),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: PrismColors.bg1.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PrismColors.panelBorder),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: PrismGradients.prism,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: PrismColors.cyan.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
