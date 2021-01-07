import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';
import 'route.dart' as route;
import 'config.dart' as config;

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
  void _bootstrap() async {
    final preferences = await SharedPreferences.getInstance();

    bootstrap(
      context: context,
      preferences: preferences,
    );
  }

  @override
  void initState() {
    super.initState();

    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convexity',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: route.routes(),
      initialRoute: config.isDebug() ? route.dev : route.launcher,
    );
  }
}
