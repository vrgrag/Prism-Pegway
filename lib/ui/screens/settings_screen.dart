import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/audio_manager.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../data/models/settings.dart';
import '../nav.dart';
import '../widgets/common.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_button.dart';
import '../widgets/prism_background.dart';
import 'webview_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateScope.of(context);

    GameSettings s() => state.settings;
    void apply(GameSettings next) => state.updateSettings(next);

    return Scaffold(
      body: PrismBackground(
        image: null,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      NeonBack(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 14),
                      Text('Settings', style: PrismText.title(26)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GlassPanel(
                    child: Column(
                      children: [
                        const SectionTitle('Audio'),
                        const SizedBox(height: 14),
                        _ToggleRow(
                          label: 'Music',
                          value: s().musicOn,
                          onChanged: (v) => apply(
                            GameSettings(
                              musicOn: v,
                              soundOn: s().soundOn,
                              hapticsOn: s().hapticsOn,
                              musicVolume: s().musicVolume,
                              effectsVolume: s().effectsVolume,
                            ),
                          ),
                        ),
                        _ToggleRow(
                          label: 'Sound Effects',
                          value: s().soundOn,
                          onChanged: (v) => apply(
                            GameSettings(
                              musicOn: s().musicOn,
                              soundOn: v,
                              hapticsOn: s().hapticsOn,
                              musicVolume: s().musicVolume,
                              effectsVolume: s().effectsVolume,
                            ),
                          ),
                        ),
                        _SliderRow(
                          label: 'Music Volume',
                          value: s().musicVolume,
                          onChanged: (v) => apply(
                            GameSettings(
                              musicOn: s().musicOn,
                              soundOn: s().soundOn,
                              hapticsOn: s().hapticsOn,
                              musicVolume: v,
                              effectsVolume: s().effectsVolume,
                            ),
                          ),
                        ),
                        _SliderRow(
                          label: 'Effects Volume',
                          value: s().effectsVolume,
                          onChanged: (v) => apply(
                            GameSettings(
                              musicOn: s().musicOn,
                              soundOn: s().soundOn,
                              hapticsOn: s().hapticsOn,
                              musicVolume: s().musicVolume,
                              effectsVolume: v,
                            ),
                          ),
                          onChangeEnd: (_) =>
                              AudioManager.instance.playSfx(Sfx.click),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassPanel(
                    child: Column(
                      children: [
                        const SectionTitle(
                          'Gameplay',
                          accent: PrismColors.violet,
                        ),
                        const SizedBox(height: 14),
                        _ToggleRow(
                          label: 'Haptics',
                          value: s().hapticsOn,
                          onChanged: (v) => apply(
                            GameSettings(
                              musicOn: s().musicOn,
                              soundOn: s().soundOn,
                              hapticsOn: v,
                              musicVolume: s().musicVolume,
                              effectsVolume: s().effectsVolume,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassPanel(
                    child: Column(
                      children: [
                        const SectionTitle(
                          'Statistics',
                          accent: PrismColors.green,
                        ),
                        const SizedBox(height: 12),
                        _StatLine(
                          'Levels completed',
                          '${state.levelsCompleted} / 40',
                        ),
                        _StatLine('Total stars', '${state.totalStars} / 120'),
                        _StatLine(
                          'Crystals collected',
                          '${state.stats.totalCrystals}',
                        ),
                        _StatLine(
                          'Total attempts',
                          '${state.stats.totalAttempts}',
                        ),
                        _StatLine(
                          'First-try wins',
                          '${state.stats.perfectRuns}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassPanel(
                    child: Column(
                      children: [
                        const SectionTitle('About', accent: PrismColors.blue),
                        const SizedBox(height: 12),
                        _LinkRow(
                          label: 'Privacy Policy',
                          icon: Icons.privacy_tip_rounded,
                          onTap: () => Navigator.of(context).push(
                            prismRoute(
                              const WebViewScreen(
                                title: 'Privacy Policy',
                                url:
                                    'https://prismpegway.com/privacy-policy.html',
                                whiteBackground: true,
                              ),
                            ),
                          ),
                        ),
                        _LinkRow(
                          label: 'Support',
                          icon: Icons.support_agent_rounded,
                          onTap: () => Navigator.of(context).push(
                            prismRoute(
                              const WebViewScreen(
                                title: 'Support',
                                url: 'https://prismpegway.com/support.html',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: 'Reset Progress',
                    icon: Icons.restart_alt_rounded,
                    gradient: PrismGradients.warm,
                    onTap: () => _confirmReset(context, state),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, GameState state) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          glow: PrismColors.magenta,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reset all progress?', style: PrismText.title(20)),
              const SizedBox(height: 10),
              Text(
                'This clears levels, stars, skins and challenges. This cannot be undone.',
                textAlign: TextAlign.center,
                style: PrismText.body(14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      label: 'Cancel',
                      gradient: PrismGradients.cool,
                      onTap: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      label: 'Reset',
                      gradient: PrismGradients.warm,
                      onTap: () {
                        state.resetProgress();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: PrismText.body(16, color: PrismColors.textHi)),
          NeonToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PrismText.body(14, color: PrismColors.textLo)),
          Slider(
            value: value.clamp(0, 1),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  const _StatLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: PrismText.body(14)),
          Text(value, style: PrismText.label(14)),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _LinkRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: PrismColors.cyan, size: 20),
            const SizedBox(width: 12),
            Text(label, style: PrismText.body(15, color: PrismColors.textHi)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: PrismColors.textLo),
          ],
        ),
      ),
    );
  }
}
