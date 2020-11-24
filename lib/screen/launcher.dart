import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:provider/provider.dart';

import './home.dart';
import './wallet.dart';
import './account.dart';
import '../nav.dart' as nav;
import '../convex.dart' as convex;

enum _PopupChoice {
  settings,
}

class LauncherScreen extends StatefulWidget {
  @override
  _LauncherScreenState createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  var currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convexity'),
        actions: [
          PopupMenuButton<_PopupChoice>(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Settings'),
                value: _PopupChoice.settings,
              )
            ],
            onSelected: (s) => nav.pushSettings(context),
          )
        ],
      ),
      body: body(context),
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }

  void _createAccount(BuildContext context) async {
    var randomKeyPair = CryptoSign.randomKeys();

    var response = await convex.faucet(
      address: Sodium.bin2hex(randomKeyPair.pk),
      amount: 1000000,
    );

    if (response.statusCode == 200) {
      var state = context.read<AppState>();

      state.addKeyPair(randomKeyPair, isPersistent: true);
      state.setActiveKeyPair(randomKeyPair, isPersistent: true);
    }
  }

  Widget body(BuildContext context) {
    var appState = context.watch<AppState>();

    if (appState.model.activeKeyPair == null) {
      return Center(
        child: ElevatedButton(
          child: Text('Create Account'),
          onPressed: () {
            _createAccount(context);
          },
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
