import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../route.dart' as route;
import '../nav.dart' as nav;
import '../widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convexity'),
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

                Navigator.pushNamed(context, route.WALLET);
              },
            ),
          ],
        ),
      ),
      body: HomeScreenBody(),
    );
  }
}

class HomeScreenBody extends StatefulWidget {
  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TODO')),
      );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final activeAddress = appState.model.activeAddress;

    void rebuild(_) {
      setState(() {});
    }

    final widgets = [
      AccountCard(
        address: activeAddress!,
        account: appState.convexClient().accountDetails(activeAddress),
      ),
      ListTile(
        leading: Icon(Icons.person),
        title: Text('Personal Token'),
        subtitle: Text('Manage your own personal token'),
        onTap: () => nav.pushSocialCurrency(context).then(rebuild),
      ),
      ListTile(
        leading: Icon(Icons.mail),
        title: Text('Inbox'),
        subtitle: Text('View your mailbox'),
        onTap: () => nav.pushInbox(context).then(rebuild),
      ),
      ListTile(
        leading: Icon(Icons.show_chart),
        title: Text('Top Currencies'),
        subtitle: Text('View top currencies in the Exchange'),
        onTap: () => nav.pushTopTokens(context).then(rebuild),
      ),
      ListTile(
        leading: Icon(Icons.shopping_bag),
        title: Text('NFT Shop'),
        subtitle: Text('Buy Unique Tokens'),
        onTap: () => nav.pushNonFungibleMarket(context).then(rebuild),
      ),
      ListTile(
        leading: Icon(Icons.videogame_asset_rounded),
        title: Text('Digital Assets'),
        subtitle: Text('View and follow Digital Assets'),
        onTap: () => nav.pushAssets(context).then(rebuild),
      ),
      ListTile(
        leading: Icon(Icons.contacts),
        title: Text('Address Book'),
        subtitle: Text('Manage trusted contacts'),
        onTap: () => nav.pushAddressBook(context).then(rebuild),
      ),
      ListTile(
        leading: Icon(Icons.money),
        title: Text('Personal Tokens'),
        subtitle: Text('View and create Fungible Tokens'),
        onTap: () => nav.pushMyTokens(context).then(rebuild),
      ),
      ListTile(
        leading: Icon(Icons.send),
        title: Text('Transfer'),
        subtitle: Text('Transfer Convex coins'),
        onTap: () => nav.pushTransfer(context).then(rebuild),
      ),
      ListTile(
        leading: Icon(Icons.money),
        title: Text('Staking'),
        subtitle: Text(''),
        onTap: () => nav.pushStaking(context).then(rebuild),
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
