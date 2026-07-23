import 'package:flutter/services.dart';

/// Short, tasteful haptic feedback. Globally gated by the player's setting so
/// callers don't each have to check it.
class Haptics {
  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
