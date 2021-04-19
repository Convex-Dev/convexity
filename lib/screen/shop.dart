import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../widget.dart';
import '../convex.dart';
import '../model.dart';

class ShopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final convexClient = appState.convexClient();

    final Future<Result> forSale = convexClient.query(
      source: '(call $SHOP_ADDRESS (shop))',
    );

    return Scaffold(
      appBar: AppBar(title: Text('Shop')),
      body: Container(
        padding: defaultScreenPadding,
        child: FutureBuilder<Result>(
          future: forSale,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(
                child: CircularProgressIndicator(),
              );

            Iterable shop = snapshot.data?.value ?? [];

            if (shop.isEmpty)
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_rounded,
                      size: 120,
                      color: Colors.black12,
                    ),
                    Gap(10),
                    Text(
                      'There is nothing for sale at the moment.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );

            return AnimationLimiter(
              child: GridView.count(
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                crossAxisCount: 2,
                children: shop
                    .map(
                      (e) => Tuple2<Address, int>(
                        Address(e['asset'].first),
                        e['asset'].last,
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
