import 'package:flutter/material.dart';

import '../../core/audio_manager.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';

/// The primary call-to-action button: a prismatic gradient pill with glow and a
/// tactile press animation. Plays a UI click and light haptic on tap.
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient gradient;
  final double height;
  final double fontSize;
  final bool enabled;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.gradient = PrismGradients.prism,
    this.height = 58,
    this.fontSize = 18,
    this.enabled = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _down = false;

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) return;
    AudioManager.instance.playSfx(Sfx.click);
    Haptics.selection();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: disabled ? 0.45 : 1,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: PrismColors.violet.withValues(alpha: 0.5),
                        blurRadius: 22,
                        spreadRadius: -2,
                      ),
                    ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: widget.fontSize + 4,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: PrismText.label(
                      widget.fontSize,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round icon button in the glass style, used for HUD controls (pause etc.).
class NeonIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final String? tooltip;

  const NeonIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = PrismColors.cyan,
    this.size = 46,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AudioManager.instance.playSfx(Sfx.click);
              Haptics.selection();
              onTap!.call();
            },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: PrismColors.bg1.withValues(alpha: 0.6),
          border: Border.all(color: color.withValues(alpha: 0.7), width: 1.4),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
