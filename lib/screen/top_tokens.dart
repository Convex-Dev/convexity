import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:flag/flag.dart';

import '../model.dart';
import '../widget.dart';
import '../format.dart' as format;
import '../nav.dart' as nav;

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
  Future<Set<AAsset>> _assets;
  Future<Result> _prices;

  FungibleToken _withToken(BuildContext context) =>
      context.read<AppState>().model.defaultWithToken ?? CVX;

  @override
  void initState() {
    super.initState();

    _assets = context.read<AppState>().convexityClient().assets();
    _assets.then((assets) {
      setState(() {
        _refreshPrices(
          context: context,
          assets: assets ?? [],
          withToken: context.read<AppState>().model.defaultWithToken?.address,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

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

        final widgets = [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Price in'),
              Gap(10),
              Dropdown<FungibleToken>(
                active: appState.model.defaultWithToken ?? CVX,
                items: [CVX, ...fungibles]..sort(
                    (a, b) => a.metadata.symbol.compareTo(b.metadata.symbol),
                  ),
                itemWidget: (FungibleToken token) {
                  return Text(token.metadata.symbol);
                },
                onChanged: (t) {
                  final defaultWithToken = t == CVX ? null : t;

                  appState.setDefaultWithToken(defaultWithToken);

                  setState(() {
                    _refreshPrices(
                      context: context,
                      assets: assets,
                      withToken: defaultWithToken?.address,
                    );
                  });
                },
              ),
            ],
          ),
          ...fungibles.map(
            (token) => ListTile(
              leading: _flag(token) ??
                  Icon(
                    Icons.circle,
                    size: 40,
                    color: Colors.black12,
                  ),
              title: Text(token.metadata.symbol),
              subtitle: Text(token.metadata.name),
              trailing: FutureBuilder<Result>(
                future: _prices,
                builder: (context, snapshot) {
                  final data = snapshot.data?.value ?? [];

                  final e = data.firstWhere(
                    (element) => Address(element['address']) == token.address,
                    orElse: () => null,
                  );

                  return AnimatedOpacity(
                    opacity: snapshot.connectionState == ConnectionState.waiting
                        ? 0
                        : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      (e == null || e['price'] == null)
                          ? ''
                          : _withToken(context).metadata.currencySymbol +
                              format.marketPriceStr(
                                format.marketPrice(
                                  ofToken: token,
                                  price: e['price'],
                                  withToken: appState.model.defaultWithToken,
                                ),
                              ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
              onTap: () {
                final result = nav.pushAsset(
                  context,
                  aasset: AAsset(
                    type: AssetType.fungible,
                    asset: token,
                  ),
                  balance:
                      appState.assetLibrary().balance(asset: token.address),
                );

                result.then(
                  (value) => setState(() {
                    _refreshPrices(
                      context: context,
                      assets: assets,
                      withToken: appState.model.defaultWithToken?.address,
                    );
                  }),
                );
              },
            ),
          ),
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
          child: SafeArea(
            child: ListView(
              children: animated,
            ),
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

  Widget _flag(FungibleToken token) {
    final mapping = {
      'GBP': 'gb',
      'USD': 'us',
      'MYR': 'my',
      'CHF': 'ch',
      'JPY': 'jp',
      'HKD': 'hk',
      'VND': 'vn',
      'THB': 'th',
    };

    final country = mapping[token.metadata.symbol];

    if (country == null) {
      return null;
    }

    return Flag(
      mapping[token.metadata.symbol],
      height: 40,
      width: 40,
    );
  }
}
