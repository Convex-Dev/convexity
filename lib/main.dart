import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;

import 'dart:convert' as convert;

import 'convex.dart' as convex;

void main() {
  sodium.Sodium.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
  int _counter = 0;
  Map _account;
  sodium.KeyPair _keyPair;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
                onPressed: () {
                  var randomKeyPair = sodium.CryptoSign.randomKeys();

                  var curve25519PK =
                      sodium.Sodium.cryptoSignEd25519PkToCurve25519(
                    randomKeyPair.pk,
                  );

                  var curve25519SK =
                      sodium.Sodium.cryptoSignEd25519SkToCurve25519(
                    randomKeyPair.sk,
                  );

                  print(
                    'PK\nEd25519 ${sodium.Sodium.bin2hex(randomKeyPair.pk)}\nCurve25519 ${sodium.Sodium.bin2hex(curve25519PK)}',
                  );

                  print(
                    'SK\nEd25519${sodium.Sodium.bin2hex(randomKeyPair.sk)}\nCurve25519 ${sodium.Sodium.bin2hex(curve25519SK)}',
                  );

                  convex
                      .faucet(
                        scheme: 'http',
                        host: '127.0.0.1',
                        port: 8080,
                        address: sodium.Sodium.bin2hex(randomKeyPair.pk),
                        amount: 1000,
                      )
                      .then((value) => convert.jsonDecode(value.body))
                      .then((body) => setState(() {
                            _account = body;
                            _keyPair = randomKeyPair;
                          }));
                },
                child: Text('Create Account')),
            Text('$_account'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
