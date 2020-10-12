import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;

import 'dart:convert' as convert;

import 'convex.dart' as convex;
import 'nav.dart' as nav;

void main() {
  sodium.Sodium.init();

  runApp(Root());
}

class Root extends StatelessWidget {
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
      home: Scaffold(
        appBar: AppBar(
          title: Text('Convex Wallet'),
        ),
        body: Center(
          child: Wallet(),
        ),
      ),
    );
  }
}

class Wallet extends StatefulWidget {
  Wallet({Key key}) : super(key: key);

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  final List<sodium.KeyPair> keyPairs = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        ElevatedButton(
          child: Text('CREATE ACCOUNT'),
          onPressed: () {
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
                  setState(() {
                    keyPairs.add(randomKeyPair);
                  });

                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Your new account is ready.'),
                    ),
                  );
                }
              },
            );
          },
        ),
        ...keyPairs.map(
          (keyPair) => Card(
            child: ListTile(
              title: Text(sodium.Sodium.bin2hex(keyPair.pk)),
              onTap: () => nav.push(
                context,
                (context) => AccountDetailsScreen(
                  address: convex.Address(
                    hex: sodium.Sodium.bin2hex(keyPair.pk),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class AccountDetailsScreen extends StatelessWidget {
  AccountDetailsScreen({
    this.address,
  }) {
    assert(address != null);
  }

  final convex.Address address;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Details'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Text('Address'),
          Text(address.hex),
        ],
      ),
    );
  }
}
