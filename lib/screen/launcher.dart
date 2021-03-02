import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../widget.dart';
import './home.dart';
import './wallet.dart';
import './account.dart';
import '../nav.dart' as nav;
import '../logger.dart';
import '../convex.dart';
import '../model.dart';

enum _PopupChoice {
  settings,
}

class LauncherScreen extends StatefulWidget {
  @override
  _LauncherScreenState createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  var isCreatingAccount = false;

  var currentIndex = 0;

  final currentIndexLabel = {
    0: 'Home',
    1: 'Wallet',
    2: 'Profile',
  };

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    var isSignedIn = appState.model.activeAddress != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSignedIn ? currentIndexLabel[currentIndex] : ''),
        actions: isSignedIn
            ? [
                PopupMenuButton<_PopupChoice>(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Settings'),
                      value: _PopupChoice.settings,
                    )
                  ],
                  onSelected: (s) => nav.pushSettings(context),
                )
              ]
            : null,
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: body(context),
      ),
      bottomNavigationBar: isSignedIn
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: currentIndexLabel[0],
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet),
                  label: currentIndexLabel[1],
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                  label: currentIndexLabel[2],
                ),
              ],
              onTap: (index) => setState(() => currentIndex = index),
            )
          : null,
    );
  }

  void _createAccount(BuildContext context) async {
    try {
      setState(() {
        isCreatingAccount = true;
      });

      var generatedKeyPair = CryptoSign.randomKeys();

      var appState = context.read<AppState>();

      final generatedAddress = await appState.convexClient().createAccount(
            AccountKey.fromBin(generatedKeyPair.pk),
          );

      if (generatedAddress != null) {
        appState.addToKeyring(
          address: generatedAddress,
          keyPair: generatedKeyPair,
        );

        appState.setActiveAddress(generatedAddress);

        appState.addContact(
          Contact(
            name: 'Account ${appState.model.keyring.length}',
            address: generatedAddress,
          ),
        );

        appState.convexClient().faucet(
              address: generatedAddress,
              amount: 100000000,
            );
      } else {
        logger.e('Failed to create Account.');
      }
    } finally {
      setState(() {
        isCreatingAccount = false;
      });
    }
  }

  Widget body(BuildContext context) {
    var appState = context.watch<AppState>();

    if (appState.model.activeAddress == null) {
      return Container(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            Text(
              'Welcome to Convex',
              style: Theme.of(context).textTheme.headline5,
            ),
            Gap(40),
            Text(
              'Convex is an open technology platform for the Internet of Value.\n\n'
              'Create your own digital assets and powerful decentralised applications for the Digital Economy of tomorrow.',
              style: TextStyle(color: Colors.black87),
            ),
            Gap(20),
            if (isCreatingAccount)
              CircularProgressIndicator()
            else ...[
              TextButton(
                child: Text('CREATE ACCOUNT'),
                onPressed: () {
                  _createAccount(context);
                },
              ),
              TextButton(
                child: Text('IMPORT EXISTING ACCOUNT'),
                onPressed: () {},
              )
            ],
          ],
        ),
      );
    }

    switch (currentIndex) {
      case 0:
        return HomeScreenBody();
      case 1:
        return WalletScreenBody();
      case 2:
        return AccountScreenBody(address: appState.model.activeAddress);
      default:
        return HomeScreenBody();
    }
  }
}
