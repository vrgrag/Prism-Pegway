import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/audio_manager.dart';
import '../../core/haptics.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../data/level_library.dart';
import '../nav.dart';
import '../widgets/common.dart';
import '../widgets/prism_background.dart';
import 'gameplay_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    return Scaffold(
      body: PrismBackground(
        image: Sprites.background(5),
        imageOpacity: 0.22,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    NeonBack(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 14),
                    Text('Select Level', style: PrismText.title(24)),
                    const Spacer(),
                    Icon(
                      Icons.star_rounded,
                      color: PrismColors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text('${state.totalStars}', style: PrismText.label(16)),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: state,
                  builder: (context, _) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: kLevels.length,
                      itemBuilder: (context, i) {
                        final level = kLevels[i];
                        final p = state.progressFor(level.id);
                        return _LevelCard(
                          number: level.id,
                          unlocked: p.unlocked,
                          stars: p.stars,
                          onTap: !p.unlocked
                              ? null
                              : () {
                                  AudioManager.instance.playSfx(Sfx.click);
                                  Haptics.selection();
                                  NavGuard.push(
                                    context,
                                    GameplayScreen(levelId: level.id),
                                  );
                                },
                        );
                      },
                    );
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

class _LevelCard extends StatelessWidget {
  final int number;
  final bool unlocked;
  final int stars;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.number,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = unlocked
        ? [
            PrismColors.cyan,
            PrismColors.violet,
            PrismColors.magenta,
            PrismColors.green,
          ][(number ~/ 5) % 4]
        : PrismColors.textDim;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: PrismColors.bg1.withValues(alpha: unlocked ? 0.7 : 0.4),
          border: Border.all(
            color: accent.withValues(alpha: unlocked ? 0.8 : 0.3),
            width: 1.4,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(
                Icons.lock_rounded,
                color: PrismColors.textDim,
                size: 26,
              )
            else
              Text('$number', style: PrismText.title(26, color: accent)),
            const SizedBox(height: 6),
            if (unlocked)
              StarRow(stars: stars, size: 12)
            else
              Text(
                'LVL $number',
                style: PrismText.body(10, color: PrismColors.textDim),
              ),
          ],
        ),
      ),
    );
  }
}
