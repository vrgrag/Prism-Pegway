import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../data/models/achievement.dart';
import '../widgets/common.dart';
import '../widgets/glass_panel.dart';
import '../widgets/prism_background.dart';

/// Read-only trophy case. Every badge is derived live from [GameState], so
/// there is nothing extra to save or corrupt.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    return Scaffold(
      body: PrismBackground(
        image: Sprites.background(4),
        imageOpacity: 0.22,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final stars = state.totalStars;
              final completed = state.levelsCompleted;
              final unlockedCount = kAchievements
                  .where(
                    (a) =>
                        a.current(state.stats, stars, completed) >= a.target,
                  )
                  .length;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        NeonBack(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 14),
                        Text('Achievements', style: PrismText.title(22)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$unlockedCount / ${kAchievements.length} unlocked',
                          style: PrismText.body(13, color: PrismColors.textLo),
                        ),
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: PrismColors.amber,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: kAchievements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final a = kAchievements[i];
                        final value = a.current(state.stats, stars, completed);
                        final done = value >= a.target;
                        return _AchievementCard(
                          achievement: a,
                          value: value,
                          done: done,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final int value;
  final bool done;
  const _AchievementCard({
    required this.achievement,
    required this.value,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? achievement.color : PrismColors.textDim;
    final progress = (value / achievement.target).clamp(0.0, 1.0);
    return GlassPanel(
      glow: color,
      glowStrength: done ? 0.32 : 0.08,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PrismColors.bg1.withValues(alpha: 0.6),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            alignment: Alignment.center,
            child: Icon(
              done ? achievement.icon : Icons.lock_outline_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: PrismText.label(
                    15,
                    color: done ? PrismColors.textHi : PrismColors.textLo,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: PrismText.body(12, color: PrismColors.textLo),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: PrismColors.bg1,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${value.clamp(0, achievement.target)} / ${achievement.target}',
                  style: PrismText.body(11, color: PrismColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
