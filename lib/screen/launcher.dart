import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './home.dart';
import './wallet.dart';
import './account.dart';
import '../nav.dart' as nav;

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
    var appState = context.watch<AppState>();

    // if (appState.model.allKeyPairs.isNotEmpty)
    //         IdenticonDropdown(
    //           activeKeyPair: appState.model.activeKeyPairOrDefault(),
    //           allKeyPairs: appState.model.allKeyPairs,
    //         ),

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
            onSelected: (s) => nav.settings(context),
          )
        ],
      ),
      body: body(appState),
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

  Widget body(AppState appState) {
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
