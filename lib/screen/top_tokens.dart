import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../widget.dart';

class TopTokensScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Top Tokens')),
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

  @override
  void initState() {
    super.initState();

    _assets = context.read<AppState>().convexityClient().assets();
  }

  @override
  Widget build(BuildContext context) {
    Widget columnText(String text) =>
        Text(text, style: Theme.of(context).textTheme.caption);

    final columns = [
      'Name',
      'Symbol',
      'Price',
    ].map((e) => TableCell(child: columnText(e))).toList();

    final appState = context.watch<AppState>();

    return FutureBuilder<Set<AAsset>>(
      future: _assets,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final assets = snapshot.data ?? <AAsset>[];

        final fungibles = assets
            .where((e) => e.type == AssetType.fungible)
            .map((e) => e.asset as FungibleToken);

        final sexp = fungibles.fold<String>(
          '',
          (sexp, token) =>
              sexp +
              '{:address ${token.address} :price (torus/price ${token.address})}',
        );

        // Single query to check the price of all Tokens.
        // Return a list of maps where each map contains the Token address and price.
        final prices = appState.convexClient().query(
              source: '(import torus.exchange :as torus) [$sexp]',
            );

        final fungibleRows = fungibles.map(
          (token) => TableRow(
            children: [
              TableCell(child: Text(token.metadata.name)),
              TableCell(child: Text(token.metadata.symbol)),
              TableCell(
                child: FutureBuilder<Result>(
                  future: prices,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('');
                    }

                    final e = snapshot.data.value.firstWhere(
                      (element) => Address(element['address']) == token.address,
                      orElse: () => null,
                    );

                    return Text('${e['price'] ?? '-'}');
                  },
                ),
              ),
            ],
          ),
        );

        return Table(
          children: [
            TableRow(children: columns),
            ...fungibleRows,
          ],
        );
      },
    );
  }
}
