import 'package:convex_wallet/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;

import 'route.dart';

void main() {
  sodium.Sodium.init();

  runApp(App());
}

class App extends StatelessWidget {
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
