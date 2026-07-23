import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/game_state.dart';
import 'ui/screens/loading_screen.dart';

/// Exposes the single [GameState] to the widget tree without a 3rd-party
/// dependency. Use `GameStateScope.of(context)`.
class GameStateScope extends InheritedNotifier<GameState> {
  const GameStateScope({
    super.key,
    required GameState state,
    required super.child,
  }) : super(notifier: state);

  static GameState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GameStateScope>();
    assert(scope?.notifier != null, 'GameStateScope not found in tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds.
  static GameState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<GameStateScope>();
    return scope!.notifier!;
  }
}

class PrismApp extends StatelessWidget {
  final GameState gameState;
  const PrismApp({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return GameStateScope(
      state: gameState,
      child: MaterialApp(
        title: 'Prism Pegway',
        debugShowCheckedModeBanner: false,
        theme: buildPrismTheme(),
        home: const LoadingScreen(),
      ),
    );
  }
}
