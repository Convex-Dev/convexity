import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../route.dart' as route;
import '../nav.dart' as nav;
import '../widget.dart';

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
  Widget action(
    BuildContext context,
    String label,
    void Function() onPressed,
  ) =>
      Column(
        children: [
          Ink(
            decoration: const ShapeDecoration(
              color: Colors.lightBlue,
              shape: CircleBorder(),
            ),
            child: IconButton(
              icon: Icon(Icons.money),
              color: Colors.white,
              onPressed: onPressed,
            ),
          ),
          Gap(6),
          Text(label)
        ],
      );

  @override
  Widget build(BuildContext context) {
    var model = context.watch<AppState>().model;

    var activeKeyPair =
        context.watch<AppState>().model.activeKeyPairOrDefault();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeKeyPair != null) ...[
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
            Center(
              child: QrImage(
                data: model.activeAddress,
                version: QrVersions.auto,
                size: 160,
              ),
            ),
          ],
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
              action(context, 'Faucet', () => nav.pushTransfer(context)),
              Gap(12),
              action(context, 'Transfer', () => nav.pushTransfer(context)),
              Gap(12),
              action(context, 'Assets', () => nav.pushAssets(context)),
              Gap(12),
              action(context, 'Quick action', () => null),
            ],
          )
        ],
      ),
    );
  }
}
