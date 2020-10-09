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
  convex.Account _account;
  sodium.KeyPair _keyPair;

  void onCreateAccountClick() {
    var randomKeyPair = sodium.CryptoSign.randomKeys();

    convex
        .faucet(
          scheme: 'http',
          host: '127.0.0.1',
          port: 8080,
          address: sodium.Sodium.bin2hex(randomKeyPair.pk),
          amount: 1000000,
        )
        .then((value) => convert.jsonDecode(value.body))
        .then(
      (body) {
        convex
            .transact(
              scheme: 'http',
              host: '127.0.0.1',
              port: 8080,
              source: '(inc 1)',
              address: sodium.Sodium.bin2hex(randomKeyPair.pk),
              secretKey: randomKeyPair.sk,
            )
            .then((value) => print('Value: ${value.value}'));

        // setState(
        //   () {
        //     _account = Account(
        //       address: Address(hex: body['address']),
        //       balance: body['value'],
        //       type: AccountType.user,
        //     );

        //     _keyPair = randomKeyPair;
        //   },
        // );
      },
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

  final convex.Account account;

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
