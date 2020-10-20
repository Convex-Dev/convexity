import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:provider/provider.dart';

import '../route.dart' as route;
import '../nav.dart' as nav;
import '../convex.dart' as convex;
import '../widget.dart';
import '../wallet.dart' as wallet;

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Convexity'),
        actions: [
          if (appState.model.allKeyPairs.isNotEmpty)
            IdenticonDropdown(
              activeKeyPair: appState.model.activeKeyPairOrDefault(),
              allKeyPairs: appState.model.allKeyPairs,
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text('Convexity'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Wallet'),
              onTap: () {
                Navigator.pop(context);

                Navigator.pushNamed(context, route.wallet);
              },
            ),
          ],
        ),
      ),
      body: HomeScreenBody(),
    );
  }
}

class HomeScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var activeKeyPair =
        context.watch<AppState>().model.activeKeyPairOrDefault();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeKeyPair == null)
            Center(
              child: ElevatedButton(
                child: Text('CREATE ACCOUNT'),
                onPressed: () {
                  var randomKeyPair = CryptoSign.randomKeys();

                  convex
                      .faucet(
                    address: Sodium.bin2hex(randomKeyPair.pk),
                    amount: 1000000,
                  )
                      .then(
                    (response) {
                      if (response.statusCode == 200) {
                        context.read<AppState>().addKeyPair(randomKeyPair);

                        wallet.addKeyPair(randomKeyPair);
                      }
                    },
                  );
                },
              ),
            )
          else ...[
            Text(Sodium.bin2hex(activeKeyPair.pk)),
            OutlinedButton(
              child: Text('Account Details'),
              onPressed: () {
                nav.account(
                  context,
                  convex.Address(hex: Sodium.bin2hex(activeKeyPair.pk)),
                );
              },
            ),
            OutlinedButton(
              onPressed: () {},
              child: Text('Action 1'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: Text('Action 2'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: Text('Action 3'),
            ),
          ],
        ],
      ),
    );
  }
}
