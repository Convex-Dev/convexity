import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
    var activeKeyPair =
        context.watch<AppState>().model.activeKeyPairOrDefault();
    var actionList = [
      {'label': "Address Book", 'function': () => nav.pushAddressBook(context)},
      {'label': "My Tokens", "function": () => nav.pushMyTokens(context)},
      {'label': "Assets", "function": () => nav.pushAssets(context)},
      {'label': "Transfer", "function": () => nav.pushTransfer(context)},
      {'label': "Fuacet", "function": () => showTodoSnackBar(context)},
      {'label': "Exchange", "function": () => showTodoSnackBar(context)},
      {'label': "Deals", "function": () => showTodoSnackBar(context)},
      {'label': "Shop", "function": () => showTodoSnackBar(context)},
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
                      Address.fromKeyPair(activeKeyPair).toString(),
                    ),
                  ),
                ],
              ),
            ),
          Gap(20),
          Expanded(
            child: AnimationLimiter(
              child: GridView.builder(
                primary: false,
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemCount: actionList.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    columnCount: 4,
                    duration: Duration(milliseconds: 300),
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: action(
                          context,
                          actionList[index]['label'].toString(),
                          actionList[index]['function'],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
