import 'package:convex_wallet/convex.dart';
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

    final columns = ['Name', 'Symbol', 'Price', 'Liquidity']
        .map((e) => TableCell(child: columnText(e)))
        .toList();

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

        final fungibleRows = fungibles.map(
          (token) => TableRow(
            children: [
              TableCell(child: Text(token.metadata.name)),
              TableCell(child: Text(token.metadata.symbol)),
              TableCell(child: Text('1')),
              TableCell(child: Text('100')),
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
