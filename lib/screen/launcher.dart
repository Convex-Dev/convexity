import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
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

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    var isSignedIn = appState.model.activeKeyPair != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Convexity'),
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
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                  label: 'Account',
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

      var randomKeyPair = CryptoSign.randomKeys();

      var appState = context.read<AppState>();

      var b = await appState.convexClient().requestForFaucet(
            address: Address.fromHex(Sodium.bin2hex(randomKeyPair.pk)),
            amount: 10000000,
          );

      if (b) {
        appState.addKeyPair(randomKeyPair, isPersistent: true);
        appState.setActiveKeyPair(randomKeyPair, isPersistent: true);
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

    if (appState.model.activeKeyPair == null) {
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
        return AccountScreenBody(
          address: Address.fromKeyPair(
            appState.model.activeKeyPair,
          ),
        );
      default:
        return HomeScreenBody();
    }
  }
}
