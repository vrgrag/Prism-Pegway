import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/audio_manager.dart';
import '../../core/haptics.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../data/models/ball_skin.dart';
import '../widgets/common.dart';
import '../widgets/prism_background.dart';

class SkinsScreen extends StatelessWidget {
  const SkinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    return Scaffold(
      body: PrismBackground(
        image: Sprites.background(7),
        imageOpacity: 0.24,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    NeonBack(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 14),
                    Text('Ball Skins', style: PrismText.title(24)),
                    const Spacer(),
                    const Icon(
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
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.86,
                          ),
                      itemCount: kBallSkins.length,
                      itemBuilder: (context, i) {
                        final skin = kBallSkins[i];
                        final unlocked = state.isSkinUnlocked(skin);
                        final selected = state.selectedSkin == skin.id;
                        return _SkinCard(
                          skin: skin,
                          unlocked: unlocked,
                          selected: selected,
                          onTap: () {
                            if (!unlocked) {
                              Haptics.medium();
                              return;
                            }
                            AudioManager.instance.playSfx(Sfx.click);
                            Haptics.selection();
                            state.selectSkin(skin.id);
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

class _SkinCard extends StatelessWidget {
  final BallSkin skin;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: PrismColors.bg1.withValues(alpha: 0.6),
          border: Border.all(
            color: selected ? PrismColors.cyan : PrismColors.panelBorder,
            width: selected ? 2.2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: PrismColors.cyan.withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: unlocked ? 1 : 0.3,
                  child: Image.asset(
                    Sprites.skin(skin.index),
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.circle, size: 90),
                  ),
                ),
                if (!unlocked)
                  const Icon(
                    Icons.lock_rounded,
                    color: PrismColors.textHi,
                    size: 34,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(skin.name, style: PrismText.label(15)),
            const SizedBox(height: 4),
            if (unlocked)
              Text(
                selected ? 'Selected' : 'Tap to equip',
                style: PrismText.body(
                  11,
                  color: selected ? PrismColors.cyan : PrismColors.textLo,
                ),
              )
            else
              Text(
                skin.dailyReward
                    ? 'Daily reward'
                    : '${skin.starsRequired}★ to unlock',
                style: PrismText.body(11, color: PrismColors.amber),
              ),
          ],
        ),
      ),
    );
  }
}
