import 'package:flutter/material.dart';

/// Prevents a burst of rapid taps (double/triple-tap on a card or button)
/// from pushing the same route multiple times, which would otherwise spin up
/// several heavyweight screens (each with its own Flame game, image decodes
/// and audio players) at once and stall the UI thread.
class NavGuard {
  static bool _busy = false;

  static Future<void> push<T>(BuildContext context, Widget page) async {
    if (_busy) return;
    _busy = true;
    try {
      await Navigator.of(context).push<T>(prismRoute(page));
    } finally {
      _busy = false;
    }
  }

  static Future<void> pushReplacement<T>(
    BuildContext context,
    Widget page,
  ) async {
    if (_busy) return;
    _busy = true;
    try {
      await Navigator.of(context).pushReplacement<T, void>(prismRoute(page));
    } finally {
      _busy = false;
    }
  }
}

/// A soft fade+scale page transition used throughout the game for a smooth,
/// loading-free feel between screens.
Route<T> prismRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
