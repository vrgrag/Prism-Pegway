import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_button.dart';

/// Semi-transparent modal backdrop shared by all in-game overlays.
class _Backdrop extends StatelessWidget {
  final Widget child;
  const _Backdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: child,
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHowToPlay;
  final VoidCallback onMenu;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onHowToPlay,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return _Backdrop(
      child: GlassPanel(
        glow: PrismColors.cyan,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused', style: PrismText.title(28)),
            const SizedBox(height: 22),
            NeonButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              onTap: onResume,
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: 'Restart',
              icon: Icons.refresh_rounded,
              gradient: PrismGradients.cool,
              onTap: onRestart,
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: 'How to Play',
              icon: Icons.school_rounded,
              gradient: PrismGradients.cool,
              onTap: onHowToPlay,
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: 'Main Menu',
              icon: Icons.home_rounded,
              gradient: PrismGradients.warm,
              onTap: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}

class LevelCompleteOverlay extends StatelessWidget {
  final int stars;
  final int score;
  final int bestScore;
  final int crystals;
  final int totalCrystals;
  final int objectsUsed;
  final String message;
  final bool hasNext;
  final VoidCallback? onNext;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const LevelCompleteOverlay({
    super.key,
    required this.stars,
    required this.score,
    required this.bestScore,
    required this.crystals,
    required this.totalCrystals,
    required this.objectsUsed,
    required this.message,
    required this.hasNext,
    required this.onNext,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return _Backdrop(
      child: GlassPanel(
        glow: PrismColors.green,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Level Complete', style: PrismText.title(26)),
            const SizedBox(height: 14),
            _AnimatedStars(stars: stars),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PrismText.body(15, color: PrismColors.cyan),
            ),
            const SizedBox(height: 16),
            _StatRow(label: 'Score', value: '$score'),
            _StatRow(
              label: 'Best',
              value: '${bestScore > score ? bestScore : score}',
            ),
            _StatRow(label: 'Crystals', value: '$crystals / $totalCrystals'),
            _StatRow(label: 'Objects used', value: '$objectsUsed'),
            const SizedBox(height: 20),
            if (hasNext)
              NeonButton(
                label: 'Next Level',
                icon: Icons.arrow_forward_rounded,
                onTap: onNext,
              ),
            if (hasNext) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'Retry',
                    gradient: PrismGradients.cool,
                    onTap: onRetry,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeonButton(
                    label: 'Menu',
                    gradient: PrismGradients.warm,
                    onTap: onMenu,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LevelFailedOverlay extends StatelessWidget {
  final int crystals;
  final int totalCrystals;
  final String message;
  final VoidCallback onEdit;
  final VoidCallback onMenu;

  const LevelFailedOverlay({
    super.key,
    required this.crystals,
    required this.totalCrystals,
    required this.message,
    required this.onEdit,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return _Backdrop(
      child: GlassPanel(
        glow: PrismColors.magenta,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Not Quite', style: PrismText.title(26)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PrismText.body(15, color: PrismColors.magenta),
            ),
            const SizedBox(height: 14),
            _StatRow(label: 'Crystals', value: '$crystals / $totalCrystals'),
            const SizedBox(height: 20),
            NeonButton(
              label: 'Edit & Retry',
              icon: Icons.build_rounded,
              onTap: onEdit,
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: 'Main Menu',
              icon: Icons.home_rounded,
              gradient: PrismGradients.warm,
              onTap: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: PrismText.body(14)),
          Text(value, style: PrismText.label(15)),
        ],
      ),
    );
  }
}

class _AnimatedStars extends StatefulWidget {
  final int stars;
  const _AnimatedStars({required this.stars});

  @override
  State<_AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<_AnimatedStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final filled = i < widget.stars;
            final start = i * 0.25;
            final t = ((_c.value - start) / 0.4).clamp(0.0, 1.0);
            final scale = filled ? (0.4 + 0.6 * t) * (1 + 0.15 * (1 - t)) : 1.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 44,
                  color: filled ? PrismColors.amber : PrismColors.textDim,
                  shadows: filled
                      ? [const Shadow(color: PrismColors.amber, blurRadius: 18)]
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
