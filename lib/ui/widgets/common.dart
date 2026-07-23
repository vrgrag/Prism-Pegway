import 'package:flutter/material.dart';

import '../../core/audio_manager.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';

/// A row of up to three glowing stars used on cards and result screens.
class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarRow({super.key, required this.stars, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: filled ? PrismColors.amber : PrismColors.textDim,
            shadows: filled
                ? [const Shadow(color: PrismColors.amber, blurRadius: 12)]
                : null,
          ),
        );
      }),
    );
  }
}

/// A custom neon on/off toggle (styled, not a default Material Switch).
class NeonToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const NeonToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playSfx(Sfx.click);
        Haptics.selection();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 60,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: value ? PrismGradients.cool : null,
          color: value ? null : PrismColors.bg1,
          border: Border.all(
            color: value ? PrismColors.cyan : PrismColors.textDim,
            width: 1.2,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: PrismColors.cyan.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small uppercase section heading with an accent bar.
class SectionTitle extends StatelessWidget {
  final String text;
  final Color accent;
  const SectionTitle(this.text, {super.key, this.accent = PrismColors.cyan});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(text.toUpperCase(), style: PrismText.label(15)),
      ],
    );
  }
}

/// Screen back button used by full-screen views without a Material AppBar.
class NeonBack extends StatelessWidget {
  final VoidCallback onTap;
  const NeonBack({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playSfx(Sfx.click);
        Haptics.selection();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: PrismColors.bg1.withValues(alpha: 0.6),
          border: Border.all(color: PrismColors.panelBorder),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: PrismColors.textHi),
      ),
    );
  }
}
