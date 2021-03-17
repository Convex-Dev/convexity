import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../widget.dart';
import '../format.dart' as format;

class TopTokensScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Top Currencies')),
      body: Container(
        padding: defaultScreenPadding,
        child: TopTokensScreenBody(),
      ),
    );
  }
}

class TopTokensScreenBody extends StatefulWidget {
  @override
  _TopTokensScreenBodyState createState() => _TopTokensScreenBodyState();
}

class _TopTokensScreenBodyState extends State<TopTokensScreenBody> {
  FungibleToken _defaultToken;
  Future<Set<AAsset>> _assets;
  Future<Result> _prices;

  FungibleToken get _withToken => _defaultToken ?? CVX;

  @override
  void initState() {
    super.initState();

    _assets = context.read<AppState>().convexityClient().assets();
    _assets.then((assets) {
      setState(() {
        _refreshPrices(
          context: context,
          assets: assets ?? [],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget columnText(String text) => Text(
          text,
          style: Theme.of(context).textTheme.caption,
        );

    return FutureBuilder<Set<AAsset>>(
      future: _assets,
      builder: (context, snapshot) {
        final assets = snapshot.data ?? <AAsset>[];

        final fungibles = assets
            .where((e) => e.type == AssetType.fungible)
            .map((e) => e.asset as FungibleToken);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return SafeArea(
          child: ListView(
            children: [
              Dropdown<FungibleToken>(
                active: _defaultToken ?? CVX,
                items: [CVX, ...fungibles],
                itemWidget: (FungibleToken token) {
                  return Text(token.metadata.symbol);
                },
                onChanged: (t) {
                  setState(() {
                    _defaultToken = t == CVX ? null : t;

                    _refreshPrices(
                      context: context,
                      assets: assets,
                      withToken: _defaultToken?.address,
                    );
                  });
                },
              ),
              ...fungibles.map(
                (token) => ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text(token.metadata.symbol),
                  subtitle: Text(token.metadata.name),
                  trailing: FutureBuilder<Result>(
                    future: _prices,
                    builder: (context, snapshot) {
                      final data = snapshot.data?.value ?? [];

                      final e = data.firstWhere(
                        (element) =>
                            Address(element['address']) == token.address,
                        orElse: () => null,
                      );

                      return AnimatedOpacity(
                        opacity:
                            snapshot.connectionState == ConnectionState.waiting
                                ? 0
                                : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          (e == null || e['price'] == null)
                              ? ''
                              : _withToken.metadata.currencySymbol +
                                  format.marketPriceStr(
                                    format.marketPrice(
                                      ofToken: token,
                                      price: e['price'],
                                      withToken: _defaultToken,
                                    ),
                                  ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _refreshPrices({
    BuildContext context,
    Set<AAsset> assets,
    Address withToken,
  }) {
    final fungibles = assets
        .where((e) => e.type == AssetType.fungible)
        .map((e) => e.asset as FungibleToken);

    final sexp = fungibles.fold<String>(
      '',
      (sexp, token) =>
          sexp +
          '{:address ${token.address} :price (torus/price ${token.address} ${withToken ?? ''})}',
    );

    // Single query to check the price of all Tokens.
    // Return a list of maps where each map contains the Token address and price.
    _prices = context.read<AppState>().convexClient().query(
          source: '(import torus.exchange :as torus) [$sexp]',
        );
  }
}
