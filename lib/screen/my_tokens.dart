import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';

class MyTokensScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tokens'),
      ),
      body: MyTokensScreenBody(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => nav.pushNewToken(context),
      ),
    );
  }
}

class MyTokensScreenBody extends StatefulWidget {
  @override
  _MyTokensScreenBodyState createState() => _MyTokensScreenBodyState();
}

class _MyTokensScreenBodyState extends State<MyTokensScreenBody> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: appState.model.myTokens.map((aasset) {
        if (aasset.type == AssetType.fungible) {
          return fungibleTokenRenderer(
            fungible: aasset.asset as FungibleToken,
            balance: appState.fungibleClient().balance(
                  token: aasset.asset.address,
                  holder: appState.model.activeAddress,
                ),
            onTap: (fungible) {
              // This seems a little bit odd, but once the route pops,
              // we call `setState` to ask Flutter to rebuild this Widget,
              // which will then create new Future objects
              // for each Token & balance.
              nav
                  .pushAsset(
                    context,
                    AAsset(
                      type: AssetType.fungible,
                      asset: fungible,
                    ),
                  )
                  .then((value) => setState(() {}));
            },
          );
        }

        return nonFungibleTokenRenderer();
      }).toList(),
    );
  }
}
