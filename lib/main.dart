import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'route.dart';
import 'model.dart';
import 'wallet.dart' as wallet;
import 'asset_manager.dart' as asset_manager;

void main() {
  sodium.Sodium.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(model: Model()),
      child: App(),
    ),
  );
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  void bootstrap() async {
    var preferences = await SharedPreferences.getInstance();

    var allKeyPairs = wallet.allKeyPairs(preferences);
    var activeKeyPair = wallet.activeKeyPair(preferences);
    var following = asset_manager.following(preferences);

    context.read<AppState>().setState(
          (_) => Model(
            allKeyPairs: allKeyPairs,
            activeKeyPair: activeKeyPair,
            following: following,
          ),
        );
  }

  @override
  void initState() {
    super.initState();

    bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convex Wallet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: routes(),
    );
  }
}
