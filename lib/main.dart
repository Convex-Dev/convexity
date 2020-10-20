import 'dart:developer';

import 'package:convex_wallet/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:provider/provider.dart';

import 'route.dart';
import 'model.dart';
import 'wallet.dart' as wallet;

void main() {
  sodium.Sodium.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(model: Model()),
      child: App(),
    ),
  );
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize *all* Key Pairs.
    wallet.keyPairs().then(
      (keyPairs) {
        log('Init *all* Key Pairs: ${keyPairs.map((e) => Sodium.bin2hex(e.pk))}');

        context.read<AppState>().addKeyPairs(keyPairs);
      },
    );

    // Initialize *active* Key Pair.
    wallet.activeKeyPair().then(
      (activeKeyPair) {
        if (activeKeyPair != null) {
          log('Init *active* Key Pair: ${Sodium.bin2hex(activeKeyPair.pk)}');

          context.read<AppState>().setActiveKeyPair(activeKeyPair);
        }
      },
    );

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
