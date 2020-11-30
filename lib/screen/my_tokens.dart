import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../convex.dart';
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

class MyTokensScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var myTokens = context.watch<AppState>().model.myTokens;

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: myTokens.where((aasset) {
        return aasset.type == AssetType.fungible;
      }).map((aasset) {
        return FungibleTokenRenderer(
          aasset: aasset,
          onTap: (aasset) => nav.pushAsset(context, aasset),
        );
      }).toList(),
    );
  }
}
