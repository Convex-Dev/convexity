import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';

// Screen for Digital Assets
class AssetsScreen extends StatefulWidget {
  @override
  _AssetsScreenState createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  Map<AAsset, Future> _balancheCache = {};

  @override
  void initState() {
    super.initState();

    _refreshBalanceCache(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Assets'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _refreshBalanceCache(context);
              });
            },
          ),
        ],
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AssetCollection(
                  assets: appState.model.following,
                  balanceCache: _balancheCache,
                ),
              ),
              SizedBox(
                height: defaultButtonHeight,
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('Follow more Assets...'),
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

  /// Refresh balance.
  ///
  /// Sets [_balancheCache].
  void _refreshBalanceCache(BuildContext context) {
    final appState = context.read<AppState>();
    final assetLibrary = appState.assetLibrary();

    // Query/cache balance for each Asset the user follows.
    _balancheCache = Map.fromEntries(
      appState.model.following.map(
        (aasset) => MapEntry(
          aasset,
          assetLibrary.balance(
            asset: aasset.asset.address,
            owner: appState.model.activeAddress,
          ),
        ),
      ),
    );
  }
}
