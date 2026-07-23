import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A performant animated neon backdrop: a radial dark gradient, an optional
/// blurred location image, and a small field of drifting glow particles.
class PrismBackground extends StatefulWidget {
  final Widget child;
  final String? image;
  final double imageOpacity;
  final int particleCount;

  const PrismBackground({
    super.key,
    required this.child,
    this.image,
    this.imageOpacity = 0.35,
    this.particleCount = 26,
  });

  @override
  State<PrismBackground> createState() => _PrismBackgroundState();
}

class _PrismBackgroundState extends State<PrismBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _particles = List.generate(widget.particleCount, (_) => _Particle(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: PrismGradients.backdrop),
        ),
        if (widget.image != null)
          Opacity(
            opacity: widget.imageOpacity,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Image.asset(
                widget.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(_particles, _controller.value),
              size: Size.infinite,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  final double x;
  final double baseY;
  final double speed;
  final double radius;
  final Color color;
  final double phase;

  _Particle(math.Random rng)
    : x = rng.nextDouble(),
      baseY = rng.nextDouble(),
      speed = 0.3 + rng.nextDouble() * 0.7,
      radius = 1.2 + rng.nextDouble() * 2.8,
      phase = rng.nextDouble(),
      color = [
        PrismColors.cyan,
        PrismColors.violet,
        PrismColors.magenta,
        PrismColors.blue,
      ][rng.nextInt(4)];
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.baseY - t * p.speed) % 1.0;
      final dy = y < 0 ? y + 1 : y;
      final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * math.sin((t + p.phase) * 6.28));
      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.5 * twinkle)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(p.x * size.width, dy * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
