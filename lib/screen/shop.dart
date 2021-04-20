import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../widget.dart';
import '../model.dart';
import '../shop.dart' as shop;
import '../nav.dart' as nav;

class ShopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final convexClient = appState.convexClient();

    return Scaffold(
      appBar: AppBar(title: Text('Shop')),
      body: Container(
        padding: defaultScreenPadding,
        child: FutureBuilder<List<shop.Listing>>(
          future: shop.listings(convexClient),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(
                child: CircularProgressIndicator(),
              );

            List<shop.Listing> listings =
                snapshot.data == null ? [] : snapshot.data!;

            if (listings.isEmpty)
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
                children: listings.asMap().entries.map(
                  (entry) {
                    return AnimationConfiguration.staggeredGrid(
                      position: entry.key,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: _ListingGridTile(
                            listing: entry.value,
                            onTap: () {
                              nav.pushListing(
                                context,
                                listing: entry.value,
                              );
                            },
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

class _ListingGridTile extends StatelessWidget {
  final shop.Listing listing;
  final void Function() onTap;

  const _ListingGridTile({
    Key? key,
    required this.listing,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: GridTile(
        child: Text(''),
        footer: GridTileBar(
          title: Text(
            '${listing.price.item1} ${listing.price.item2 ?? 'CVX'}',
            style: TextStyle(color: Colors.black87),
          ),
          backgroundColor: Colors.black12,
        ),
      ),
      onTap: onTap,
    );

    return Container();
  }
}
