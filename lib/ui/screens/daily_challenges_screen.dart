import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/audio_manager.dart';
import '../../core/haptics.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../data/models/daily_challenge.dart';
import '../widgets/common.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_button.dart';
import '../widgets/prism_background.dart';

class DailyChallengesScreen extends StatelessWidget {
  const DailyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    return Scaffold(
      body: PrismBackground(
        image: Sprites.background(6),
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
                    Text('Daily Challenges', style: PrismText.title(22)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Text(
                  'New challenges every day. Complete them to unlock cosmetic rewards.',
                  style: PrismText.body(13, color: PrismColors.textLo),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: state,
                  builder: (context, _) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: state.dailies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final d = state.dailies[i];
                        return _ChallengeCard(
                          challenge: d,
                          onClaim: () {
                            state.claimDaily(d);
                            AudioManager.instance.playSfx(Sfx.reward);
                            Haptics.success();
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

class _ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final VoidCallback onClaim;
  const _ChallengeCard({required this.challenge, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final done = challenge.completed;
    final color = challenge.claimed
        ? PrismColors.textDim
        : (done ? PrismColors.green : PrismColors.cyan);
    return GlassPanel(
      glow: color,
      glowStrength: 0.22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(challenge.type.title, style: PrismText.label(16)),
              ),
              if (challenge.claimed)
                const Icon(
                  Icons.check_circle_rounded,
                  color: PrismColors.textDim,
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            challenge.type.describe(challenge.target),
            style: PrismText.body(13),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: PrismColors.bg1,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: challenge.ratio,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: PrismGradients.cool,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.progress} / ${challenge.target}',
                style: PrismText.body(12, color: PrismColors.textLo),
              ),
              if (done && !challenge.claimed)
                SizedBox(
                  height: 38,
                  child: NeonButton(
                    label: 'Claim',
                    height: 38,
                    fontSize: 14,
                    onTap: onClaim,
                  ),
                )
              else if (challenge.claimed)
                Text(
                  'Claimed',
                  style: PrismText.label(13, color: PrismColors.textDim),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
