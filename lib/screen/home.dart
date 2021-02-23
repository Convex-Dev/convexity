import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';

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
    final widgets = [
      ActiveAccount2(),
      ListTile(
        leading: Icon(Icons.videogame_asset_rounded),
        title: Text('Digital Assets'),
        subtitle: Text('View and follow Digital Assets'),
        onTap: () => nav.pushAssets(context),
      ),
      ListTile(
        leading: Icon(Icons.shopping_bag_sharp),
        title: Text('Exchange'),
        subtitle: Text('Buy and sell Tokens'),
        onTap: () => nav.pushExchange(context),
      ),
      ListTile(
        leading: Icon(Icons.contacts),
        title: Text('Address Book'),
        subtitle: Text('Manage trusted contacts'),
        onTap: () => nav.pushAddressBook(context),
      ),
      ListTile(
        leading: Icon(Icons.money),
        title: Text('Personal Tokens'),
        subtitle: Text('View and create Fungible Tokens'),
        onTap: () => nav.pushMyTokens(context),
      ),
      ListTile(
        leading: Icon(Icons.send),
        title: Text('Transfer'),
        subtitle: Text('Transfer Convex coins'),
        onTap: () => nav.pushTransfer(context),
      ),
      ListTile(
        leading: Icon(Icons.money),
        title: Text('Staking'),
        subtitle: Text(''),
        onTap: () => nav.pushStaking(context),
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
