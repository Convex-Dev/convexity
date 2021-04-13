import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../convex.dart';
import '../model.dart';
import '../widget.dart';

class NonFungibleSellScreen extends StatefulWidget {
  @override
  _NonFungibleSellScreenState createState() => _NonFungibleSellScreenState();
}

class _NonFungibleSellScreenState extends State<NonFungibleSellScreen> {
  FungibleToken? _token;
  Future<Set<AAsset>?>? _assets;

  @override
  void initState() {
    super.initState();

    _assets = context.read<AppState>().convexityClient().assets();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text('Sell Non-Fungible Token')),
      body: Container(
        padding: defaultScreenPadding,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Price',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                Gap(10),
                FutureBuilder<Set<AAsset>?>(
                  future: _assets,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Spinner();
                    }

                    final assets = snapshot.data ?? <AAsset>[];

                    final fungibles = assets
                        .where(
                          (e) =>
                              e.type == AssetType.fungible &&
                              isDefaultFungibleToken(e.asset),
                        )
                        .map((e) => e.asset as FungibleToken);

                    return Dropdown<FungibleToken>(
                      active: _token ?? appState.model.defaultWithToken ?? CVX,
                      items: [CVX, ...fungibles]..sort(
                          (a, b) => a.metadata.tickerSymbol!
                              .compareTo(b.metadata.tickerSymbol!),
                        ),
                      itemWidget: (FungibleToken token) {
                        return Text(token.metadata.tickerSymbol!);
                      },
                      onChanged: (t) {
                        setState(() {
                          _token = t;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
            Gap(20),
            ElevatedButton(
              child: Text('Sell'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
