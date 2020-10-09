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
  Account _account;
  sodium.KeyPair _keyPair;

  void onCreateAccountClick() {
    var randomKeyPair = sodium.CryptoSign.randomKeys();

    var curve25519PK = sodium.Sodium.cryptoSignEd25519PkToCurve25519(
      randomKeyPair.pk,
    );

    var curve25519SK = sodium.Sodium.cryptoSignEd25519SkToCurve25519(
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
        .then(
          (body) => setState(
            () {
              _account = Account(
                address: Address(hex: body['address']),
                balance: body['value'],
                type: AccountType.user,
              );

              _keyPair = randomKeyPair;
            },
          ),
        );
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
        child: _account == null
            ? WelcomeNoAccount(
                onCreateAccountClick: onCreateAccountClick,
              )
            : AccountDetails(
                account: _account,
              ),
      ),
    );
  }
}

class WelcomeNoAccount extends StatelessWidget {
  WelcomeNoAccount({Key key, this.onCreateAccountClick}) : super(key: key);

  final Function onCreateAccountClick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          onPressed: onCreateAccountClick,
          child: Text('CREATE ACCOUNT'),
        ),
      ],
    );
  }
}

class AccountDetails extends StatelessWidget {
  AccountDetails({Key key, this.account}) : super(key: key);

  final Account account;

  @override
  Widget build(BuildContext context) {
    print(account);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text('ADDRESS'),
        Text('${account.address.hex}'),
        Text('BALANCE'),
        Text('${account.balance}'),
        Text('TYPE'),
        Text('${account.type.toString()}'),
      ],
    );
  }
}

class Address {
  final String hex;

  Address({this.hex});
}

enum AccountType {
  user,
  library,
  actor,
}

class Account {
  final Address address;
  final int balance;
  final AccountType type;

  Account({this.address, this.balance, this.type});
}
