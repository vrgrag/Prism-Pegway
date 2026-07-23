import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/game_state.dart';
import 'data/save_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The whole game runs strictly in portrait.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final saveManager = SaveManager();
  final gameState = GameState(saveManager);
  runApp(PrismApp(gameState: gameState));
}
