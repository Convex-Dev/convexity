import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;

import 'dart:convert' as convert;

import 'convex.dart' as convex;

void main() {
  sodium.Sodium.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      home: MyHomePage(title: 'Convex Wallet'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<sodium.KeyPair> _wallet = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            ElevatedButton(
              onPressed: createAccount,
              child: Text('CREATE ACCOUNT'),
            ),
            ..._wallet.map(
              (keyPair) => WalletEntry(keyPair: keyPair),
            )
          ],
        ),
      ),
    );
  }

  void createAccount() {
    var randomKeyPair = sodium.CryptoSign.randomKeys();

    convex
        .faucet(
      scheme: 'http',
      host: '127.0.0.1',
      port: 8080,
      address: sodium.Sodium.bin2hex(randomKeyPair.pk),
      amount: 1000000,
    )
        .then(
      (response) {
        if (response.statusCode == 200) {
          setState(
            () => _wallet.add(randomKeyPair),
          );
        }
      },
    );
  }
}

class WalletEntry extends StatelessWidget {
  WalletEntry({
    Key key,
    this.keyPair,
    this.onClick,
  }) : super(key: key);

  final sodium.KeyPair keyPair;
  final Function onClick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text('Public Key'),
        Text('${sodium.Sodium.bin2hex(keyPair.pk)}'),
      ],
    );
  }
}
