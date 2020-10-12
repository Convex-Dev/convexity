import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:http/http.dart';

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
      home: WalletScreen(),
    );
  }
}

class WalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convex Wallet'),
      ),
      body: WalletScreenBody(),
    );
  }
}

class WalletScreenBody extends StatefulWidget {
  WalletScreenBody({Key key}) : super(key: key);

  @override
  _WalletScreenBodyState createState() => _WalletScreenBodyState();
}

class _WalletScreenBodyState extends State<WalletScreenBody> {
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
  final convex.Address address;

  AccountDetailsScreen({
    this.address,
  }) {
    assert(address != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account Details')),
      body: AccountDetailsScreenBody(address: address),
    );
  }
}

class AccountDetailsScreenBody extends StatefulWidget {
  final convex.Address address;

  const AccountDetailsScreenBody({Key key, this.address}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _AccountDetailsScreenBodyState(address);
}

class _AccountDetailsScreenBodyState extends State<AccountDetailsScreenBody> {
  final convex.Address address;

  Future<Response> response;

  _AccountDetailsScreenBodyState(this.address);

  @override
  void initState() {
    super.initState();

    response = convex.account(
      scheme: 'http',
      host: '127.0.0.1',
      port: 8080,
      address: address,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: response,
        // ignore: missing_return
        builder: (BuildContext context, AsyncSnapshot<Response> snapshot) {
          var progressIndicator = Center(child: CircularProgressIndicator());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return progressIndicator;
            case ConnectionState.waiting:
              return progressIndicator;
            case ConnectionState.active:
              return progressIndicator;
            case ConnectionState.done:
              var body = convert.jsonDecode(snapshot.data.body);
              return Column(
                children: [
                  Text('Address'),
                  Text(body['address']),
                  Text('Type'),
                  Text(body['type']),
                  Text('Balance'),
                  Text(body['balance'].toString()),
                  Text('Memory Size'),
                  Text(body['memory_size'].toString()),
                  Text('Memory Allowance'),
                  Text(body['allowance'].toString()),
                ],
              );
          }
        },
      );
}
