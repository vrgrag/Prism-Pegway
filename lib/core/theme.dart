import 'package:flutter/material.dart';

/// Central neon visual language for Prism Pegway. Dark base, prismatic accents,
/// glass panels and soft glow — applied consistently across every screen.
class PrismColors {
  static const Color bg0 = Color(0xFF06060F);
  static const Color bg1 = Color(0xFF0C0A22);
  static const Color panel = Color(0x1AFFFFFF); // frosted glass fill
  static const Color panelBorder = Color(0x33FFFFFF);

  static const Color cyan = Color(0xFF39E7FF);
  static const Color blue = Color(0xFF4D7BFF);
  static const Color violet = Color(0xFF9B5CFF);
  static const Color magenta = Color(0xFFFF4DD2);
  static const Color green = Color(0xFF52FFB8);
  static const Color amber = Color(0xFFFFC24D);

  static const Color textHi = Color(0xFFF3F0FF);
  static const Color textLo = Color(0xFFB9B4D6);
  static const Color textDim = Color(0xFF7C769B);
}

class PrismGradients {
  static const LinearGradient prism = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PrismColors.cyan, PrismColors.violet, PrismColors.magenta],
  );

  static const LinearGradient cool = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PrismColors.cyan, PrismColors.blue],
  );

  static const LinearGradient warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PrismColors.violet, PrismColors.magenta],
  );

  static const RadialGradient backdrop = RadialGradient(
    center: Alignment(0, -0.4),
    radius: 1.3,
    colors: [Color(0xFF181441), PrismColors.bg0],
  );
}

class PrismText {
  static TextStyle title(double size, {Color color = PrismColors.textHi}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: color,
        height: 1.05,
      );

  static TextStyle body(double size, {Color color = PrismColors.textLo}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color,
      );

  static TextStyle label(double size, {Color color = PrismColors.textHi}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      );
}

ThemeData buildPrismTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PrismColors.bg0,
    colorScheme: const ColorScheme.dark(
      primary: PrismColors.cyan,
      secondary: PrismColors.magenta,
      surface: PrismColors.bg1,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: PrismColors.cyan,
      inactiveTrackColor: Color(0x33FFFFFF),
      thumbColor: PrismColors.textHi,
      overlayColor: Color(0x3339E7FF),
      trackHeight: 5,
    ),
  );
}

/// A soft neon glow shadow used across widgets.
List<BoxShadow> neonGlow(Color color, {double blur = 18, double spread = 0}) =>
    [
      BoxShadow(
        color: color.withValues(alpha: 0.55),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
