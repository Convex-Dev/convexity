import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../convex.dart';
import '../model.dart';
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

    final widgets = [
      Card(
        child: Column(
          children: [
            ListTile(
              leading: Identicon(keyPair: activeKeyPair),
              title: Text(
                appState.model.activeAddress.toString(),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Address',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: appState.model.activeAddress.toString(),
                    ),
                  );

                  Scaffold.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
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
            FutureBuilder<Account>(
              future: appState
                  .convexClient()
                  .account(address: appState.model.activeAddress),
              builder: (context, snapshot) {
                var animatedChild;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  animatedChild = SizedBox(
                    height: 63,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'loading...',
                        style: TextStyle(color: Colors.black38),
                      ),
                    ),
                  );
                } else {
                  animatedChild = Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (snapshot.data?.balance == null
                                  ? '-'
                                  : NumberFormat()
                                      .format(snapshot.data.balance)),
                              textAlign: TextAlign.start,
                            ),
                            Text(
                              'Balance',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (snapshot.data?.memorySize?.toString() ?? '-'),
                              textAlign: TextAlign.start,
                            ),
                            Text(
                              'Memory Size',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.data?.sequence?.toString() ?? '-',
                            ),
                            Text(
                              'Sequence',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }

                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  child: animatedChild,
                );
              },
            ),
          ],
        ),
      ),
      ListTile(
        leading: Icon(Icons.contacts),
        title: Text('Address Book'),
        subtitle: Text('View and create Contacts.'),
        onTap: () => nav.pushAddressBook(context),
      ),
      ListTile(
        leading: Icon(Icons.money),
        title: Text('My Tokens'),
        subtitle: Text('View and create Fungible Tokens.'),
        onTap: () => nav.pushMyTokens(context),
      ),
      ListTile(
        leading: Icon(Icons.videogame_asset_rounded),
        title: Text('Assets'),
        subtitle: Text('Follow Assets you are interested.'),
        onTap: () => nav.pushAssets(context),
      ),
      ListTile(
        leading: Icon(Icons.send),
        title: Text('Transfer'),
        subtitle: Text('Transfer Convex coins.'),
        onTap: () => nav.pushTransfer(context),
      )
    ];

    final animated = widgets
        .asMap()
        .entries
        .map(
          (e) => AnimationConfiguration.staggeredList(
            position: e.key,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: e.value,
              ),
            ),
          ),
        )
        .toList();

    return AnimationLimiter(
      child: ListView(
        children: animated,
      ),
    );
  }
}
