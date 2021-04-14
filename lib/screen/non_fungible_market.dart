import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../widget.dart';
import '../convex.dart';
import '../model.dart';
import '../config.dart' as config;

class NonFungibleMarketScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final convexClient = appState.convexClient();

    final Future<Result> forSale = convexClient.query(
      source: '(call ${config.NFT_MARKET_ADDRESS} (for-sale))',
    );

    return Scaffold(
      appBar: AppBar(title: Text('Non-Fungible Market')),
      body: Container(
        padding: defaultScreenPadding,
        child: FutureBuilder<Result>(
          future: forSale,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(
                child: CircularProgressIndicator(),
              );

            List forSale = snapshot.data?.value ?? [];

            return AnimationLimiter(
              child: GridView.count(
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                crossAxisCount: 2,
                children: forSale
                    .map(
                      (e) => Tuple2<Address, int>(
                        Address(e['nft-address']),
                        e['token-id'],
                      ),
                    )
                    .toList()
                    .asMap()
                    .entries
                    .map(
                  (entry) {
                    final dataSource =
                        '(call ${entry.value.item1} (get-token-data ${entry.value.item2}))';

                    final data = convexClient.query(source: dataSource);

                    return AnimationConfiguration.staggeredGrid(
                      position: entry.key,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: NonFungibleGridTile(
                            tokenId: entry.value.item2,
                            data: data,
                            onTap: () {},
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
