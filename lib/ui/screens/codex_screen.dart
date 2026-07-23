import 'package:flutter/material.dart';

import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../engine/game_object.dart';
import '../widgets/common.dart';
import '../widgets/glass_panel.dart';
import '../widgets/prism_background.dart';

class _CodexEntry {
  final ObjectType type;
  final String tip;
  final Color color;
  final int variant;
  final IconData? fallbackIcon;
  const _CodexEntry(
    this.type,
    this.tip,
    this.color, {
    this.variant = 0,
    this.fallbackIcon,
  });
}

/// A standing reference of every object in the game — unlike How to Play
/// (a one-time onboarding flow), this screen is meant to be revisited any
/// time the player wants a refresher on what a piece does.
class CodexScreen extends StatelessWidget {
  const CodexScreen({super.key});

  static const List<_CodexEntry> _entries = [
    _CodexEntry(
      ObjectType.peg,
      'Tip: angle two pegs into a V to funnel the ball precisely.',
      PrismColors.cyan,
    ),
    _CodexEntry(
      ObjectType.booster,
      'Tip: chain several boosters in a row to build up serious speed.',
      PrismColors.blue,
    ),
    _CodexEntry(
      ObjectType.spring,
      'Tip: great for sending the ball straight up past obstacles.',
      PrismColors.green,
    ),
    _CodexEntry(
      ObjectType.magnet,
      'Tip: the pull weakens with distance — place it close to the path.',
      PrismColors.violet,
    ),
    _CodexEntry(
      ObjectType.prism,
      'Tip: rotate it to snap the ball onto an exact new heading.',
      PrismColors.magenta,
    ),
    _CodexEntry(
      ObjectType.teleporter,
      'Tip: linked pairs share color — momentum carries through the warp.',
      PrismColors.cyan,
    ),
    _CodexEntry(
      ObjectType.crystal,
      'Tip: every crystal on the field must be collected before the portal will work.',
      PrismColors.magenta,
    ),
    _CodexEntry(
      ObjectType.portal,
      'Tip: it stays dormant until the last crystal is collected.',
      PrismColors.amber,
      variant: 1,
    ),
    _CodexEntry(
      ObjectType.wall,
      'Tip: solid obstacles — plan a route around, not through.',
      PrismColors.textDim,
      fallbackIcon: Icons.block_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PrismBackground(
        image: Sprites.background(3),
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
                    Text('Object Codex', style: PrismText.title(22)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Text(
                  'A quick reference for everything on the field.',
                  style: PrismText.body(13, color: PrismColors.textLo),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _CodexCard(entry: _entries[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodexCard extends StatelessWidget {
  final _CodexEntry entry;
  const _CodexCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      glow: entry.color,
      glowStrength: 0.22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PrismColors.bg1.withValues(alpha: 0.6),
              border: Border.all(color: entry.color.withValues(alpha: 0.6)),
            ),
            alignment: Alignment.center,
            child: entry.fallbackIcon != null
                ? Icon(entry.fallbackIcon, color: entry.color, size: 28)
                : Image.asset(
                    Sprites.forType(entry.type, entry.variant),
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.help_outline,
                      color: entry.color,
                      size: 26,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.label,
                  style: PrismText.label(15, color: PrismColors.textHi),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.type.description,
                  style: PrismText.body(12, color: PrismColors.textLo),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.tip,
                  style: PrismText.body(
                    11.5,
                    color: entry.color,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
