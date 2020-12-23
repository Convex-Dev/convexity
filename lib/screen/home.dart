import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';

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
          Container(
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
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
            ),
          )
        ],
      );

  void showTodoSnackBar(BuildContext context) =>
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('TODO')));

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final activeKeyPair = appState.model.activeKeyPairOrDefault();

    final actions = [
      action(
        context,
        'Address Book',
        () => nav.pushAddressBook(context),
      ),
      action(
        context,
        'My Tokens',
        () => nav.pushMyTokens(context),
      ),
      action(
        context,
        'Assets',
        () => nav.pushAssets(context),
      ),
      action(
        context,
        'Transfer',
        () => nav.pushTransfer(context),
      ),
      // action(
      //   context,
      //   'Faucet',
      //   () => showTodoSnackBar(context),
      // ),
      // action(
      //   context,
      //   'Exchange',
      //   () => showTodoSnackBar(context),
      // ),
      // action(
      //   context,
      //   'Deals',
      //   () => showTodoSnackBar(context),
      // ),
      // action(
      //   context,
      //   'Shop',
      //   () => showTodoSnackBar(context),
      // ),
    ];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeKeyPair != null)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Identicon(keyPair: activeKeyPair),
                    title: Text('100,000,000'),
                    subtitle: Text(
                      appState.model.activeAddress.toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: InkWell(
                      child: IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: appState.model.activeAddress.toString(),
                            ),
                          );

                          Scaffold.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Copied ${appState.model.activeAddress.toString()}',
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Gap(20),
          Expanded(
            child: AnimationLimiter(
              child: GridView.count(
                primary: false,
                padding: const EdgeInsets.all(20),
                crossAxisSpacing: 10,
                mainAxisSpacing: 24,
                crossAxisCount: 4,
                children: actions
                    .asMap()
                    .entries
                    .map(
                      (e) => AnimationConfiguration.staggeredGrid(
                        position: e.key,
                        columnCount: 4,
                        child: ScaleAnimation(
                          child: FadeInAnimation(child: e.value),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
