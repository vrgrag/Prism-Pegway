import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../engine/game_object.dart';
import '../widgets/common.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_button.dart';
import '../widgets/prism_background.dart';

class _Step {
  final String title;
  final String text;
  final IconData? icon;
  final String? sprite;
  final Color color;
  const _Step({
    required this.title,
    required this.text,
    this.icon,
    this.sprite,
    required this.color,
  });
}

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _pc = PageController();
  int _page = 0;

  static final List<_Step> _steps = [
    const _Step(
      title: 'Your Goal',
      text:
          'Release the neon ball, collect every energy crystal, then guide it into the glowing portal.',
      icon: Icons.flag_rounded,
      color: PrismColors.green,
    ),
    const _Step(
      title: 'Build the Route',
      text:
          'Drag objects from the tray onto the grid — or tap an object, then tap a cell. Valid cells glow green.',
      icon: Icons.touch_app_rounded,
      color: PrismColors.cyan,
    ),
    const _Step(
      title: 'Rotate & Remove',
      text:
          'Tap a placed object to select it. Use rotate to aim directional parts, or delete to return it to your tray.',
      icon: Icons.rotate_right_rounded,
      color: PrismColors.blue,
    ),
    const _Step(
      title: 'Launch',
      text:
          'Hit Launch to run the simulation. Missed? Jump straight back to editing and tweak your build.',
      icon: Icons.rocket_launch_rounded,
      color: PrismColors.amber,
    ),
    _Step(
      title: 'Peg',
      text: ObjectType.peg.description,
      sprite: Sprites.forType(ObjectType.peg),
      color: PrismColors.cyan,
    ),
    _Step(
      title: 'Booster',
      text: ObjectType.booster.description,
      sprite: Sprites.forType(ObjectType.booster),
      color: PrismColors.blue,
    ),
    _Step(
      title: 'Spring',
      text: ObjectType.spring.description,
      sprite: Sprites.forType(ObjectType.spring),
      color: PrismColors.green,
    ),
    _Step(
      title: 'Magnet',
      text: ObjectType.magnet.description,
      sprite: Sprites.forType(ObjectType.magnet),
      color: PrismColors.violet,
    ),
    _Step(
      title: 'Prism',
      text: ObjectType.prism.description,
      sprite: Sprites.forType(ObjectType.prism),
      color: PrismColors.magenta,
    ),
    _Step(
      title: 'Teleporter',
      text: ObjectType.teleporter.description,
      sprite: Sprites.forType(ObjectType.teleporter),
      color: PrismColors.cyan,
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _finish() {
    GameStateScope.read(context).markTutorialSeen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;
    return Scaffold(
      body: PrismBackground(
        image: Sprites.background(1),
        imageOpacity: 0.22,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    NeonBack(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 14),
                    Text('How to Play', style: PrismText.title(24)),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _StepView(step: _steps[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? PrismColors.cyan : PrismColors.textDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: NeonButton(
                  label: isLast ? 'Got it' : 'Next',
                  icon: isLast
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  onTap: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _pc.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  final _Step step;
  const _StepView({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PrismColors.bg1.withValues(alpha: 0.5),
              border: Border.all(
                color: step.color.withValues(alpha: 0.6),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: step.color.withValues(alpha: 0.4),
                  blurRadius: 26,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: step.sprite != null
                ? Image.asset(
                    step.sprite!,
                    width: 92,
                    height: 92,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.help_outline, color: step.color, size: 60),
                  )
                : Icon(step.icon, color: step.color, size: 66),
          ),
          const SizedBox(height: 28),
          GlassPanel(
            glow: step.color,
            glowStrength: 0.3,
            child: Column(
              children: [
                Text(step.title, style: PrismText.title(24, color: step.color)),
                const SizedBox(height: 12),
                Text(
                  step.text,
                  textAlign: TextAlign.center,
                  style: PrismText.body(16, color: PrismColors.textHi),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
