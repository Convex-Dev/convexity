import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';

class AssetsScreen extends StatefulWidget {
  @override
  _AssetsScreenState createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  Map<AAsset, Future> balancheCache = {};

  @override
  void initState() {
    super.initState();

    final appState = context.read<AppState>();
    final assetLibrary = appState.assetLibrary();

    final assets = <AAsset>{}
      ..addAll(appState.model.myTokens)
      ..addAll(appState.model.following);

    balancheCache = Map.fromEntries(assets.map(
      (aasset) => MapEntry(
          aasset,
          assetLibrary.balance(
            asset: aasset.asset.address,
            owner: appState.model.activeAddress,
          )),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final assets = <AAsset>{}
      ..addAll(appState.model.myTokens)
      ..addAll(appState.model.following);

    return Scaffold(
      appBar: AppBar(title: Text('Digital Assets')),
      body: Container(
        padding: defaultScreenPadding,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AssetsCollection(
                  assets: assets,
                  balanceCache: balancheCache,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('Follow'),
                  onPressed: () {
                    nav.pushFollow(context);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
