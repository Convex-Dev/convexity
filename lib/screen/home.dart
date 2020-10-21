import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:provider/provider.dart';

import '../route.dart' as route;
import '../nav.dart' as nav;
import '../convex.dart' as convex;
import '../widget.dart';
import '../wallet.dart' as wallet;
import 'package:gap/gap.dart';

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
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }
}

class HomeScreenBody extends StatelessWidget {
  Widget action() => Column(
        children: [
          Ink(
            decoration: const ShapeDecoration(
              color: Colors.lightBlue,
              shape: CircleBorder(),
            ),
            child: IconButton(
              icon: Icon(Icons.money),
              color: Colors.white,
              onPressed: () {},
            ),
          ),
          Gap(6),
          Text('Label')
        ],
      );

  @override
  Widget build(BuildContext context) {
    var activeKeyPair =
        context.watch<AppState>().model.activeKeyPairOrDefault();

    var allKeyPairs = context.watch<AppState>().model.allKeyPairs;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Identicon(keyPair: activeKeyPair),
                  title: Text('100,000,000'),
                  subtitle: Text('Bar'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('ACTION'),
                      onPressed: () {},
                    ),
                    TextButton(
                      child: Text('ACTION'),
                      onPressed: () {},
                    )
                  ],
                )
              ],
            ),
          ),
          Gap(40),
          Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              action(),
              Gap(12),
              action(),
              Gap(12),
              action(),
              Gap(12),
              action(),
            ],
          )
        ],
      ),
    );
  }
}
