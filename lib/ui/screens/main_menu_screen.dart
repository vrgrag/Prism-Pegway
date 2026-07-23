import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/audio_manager.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../nav.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_button.dart';
import '../widgets/prism_background.dart';
import 'achievements_screen.dart';
import 'codex_screen.dart';
import 'daily_challenges_screen.dart';
import 'how_to_play_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'skins_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);
    AudioManager.instance.playMusic(MusicTrack.menu);

    return Scaffold(
      body: PrismBackground(
        image: Sprites.background(2),
        imageOpacity: 0.28,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  Sprites.logo,
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    'PRISM\nPEGWAY',
                    textAlign: TextAlign.center,
                    style: PrismText.title(44),
                  ),
                ),
                const SizedBox(height: 8),
                _StarBadge(stars: state.totalStars),
                const Spacer(flex: 2),
                NeonButton(
                  label: 'Play',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).push(prismRoute(const LevelSelectScreen())),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.emoji_events_rounded,
                        label: 'Daily',
                        color: PrismColors.amber,
                        onTap: () => Navigator.of(
                          context,
                        ).push(prismRoute(const DailyChallengesScreen())),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.blur_circular_rounded,
                        label: 'Skins',
                        color: PrismColors.magenta,
                        onTap: () => Navigator.of(
                          context,
                        ).push(prismRoute(const SkinsScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.school_rounded,
                        label: 'How to Play',
                        color: PrismColors.cyan,
                        onTap: () => Navigator.of(
                          context,
                        ).push(prismRoute(const HowToPlayScreen())),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        color: PrismColors.blue,
                        onTap: () => Navigator.of(
                          context,
                        ).push(prismRoute(const SettingsScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.emoji_events_rounded,
                        label: 'Achievements',
                        color: PrismColors.green,
                        onTap: () => Navigator.of(
                          context,
                        ).push(prismRoute(const AchievementsScreen())),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.auto_stories_rounded,
                        label: 'Codex',
                        color: PrismColors.violet,
                        onTap: () => Navigator.of(
                          context,
                        ).push(prismRoute(const CodexScreen())),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
                Text(
                  'v1.0.0  •  com.prismpegway.pegwaygame',
                  style: PrismText.body(11, color: PrismColors.textDim),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  final int stars;
  const _StarBadge({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: PrismColors.bg1.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PrismColors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: PrismColors.amber, size: 18),
          const SizedBox(width: 6),
          Text('$stars / 120', style: PrismText.label(14)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playSfx(Sfx.click);
        onTap();
      },
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 16),
        glow: color,
        glowStrength: 0.25,
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: PrismText.label(13)),
          ],
        ),
      ),
    );
  }
}
