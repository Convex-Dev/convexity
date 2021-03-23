import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../widget.dart';

class SelectFungibleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tokens')),
      body: Container(
        padding: defaultScreenPadding,
        child: _SelectFungibleScreenBody(),
      ),
    );
  }
}

class _SelectFungibleScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final fungibles = appState.model!.following.where(
      (element) => element.type == AssetType.fungible,
    );

    return AssetCollection(
      assets: fungibles,
      onAssetTap: (asset) {
        Navigator.pop(context, asset.asset as FungibleToken?);
      },
    );
  }
}
