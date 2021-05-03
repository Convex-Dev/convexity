import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../widget.dart';
import '../model.dart';
import '../shop.dart' as shop;
import '../nav.dart' as nav;
import '../format.dart' as format;

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final convexClient = appState.convexClient();

    return Scaffold(
      appBar: AppBar(title: Text('NFT Shop')),
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

            listings.sort((l1, l2) => l2.id.compareTo(l1.id));

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
                crossAxisCount: 3,
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
                              Future result = nav.pushListing(
                                context,
                                listing: entry.value,
                              );

                              result.then((value) => setState(() {}));
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
    final Future<AAsset?>? aasset = listing.price.item2 != null
        ? context
            .watch<AppState>()
            .convexityClient()
            .asset(listing.price.item2!)
        : null;

    final Widget priceWidget = aasset == null
        ? Text(
            '${shop.priceStr(listing.price)} CVX',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white),
          )
        : FutureBuilder<AAsset?>(
            future: aasset,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Getting price...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                );
              }

              FungibleTokenMetadata metadata = snapshot.data?.asset.metadata;

              return Text(
                '${format.formatFungibleCurrency(metadata: metadata, number: listing.price.item1)} ${metadata.tickerSymbol}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              );
            },
          );

    return InkWell(
      child: GridTile(
        child: listing.image == null
            ? Image.memory(kTransparentImage)
            : FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: listing.image!,
              ),
        footer: GridTileBar(
          title: Text(
            listing.description,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: priceWidget,
          backgroundColor: Colors.black54,
        ),
      ),
      onTap: onTap,
    );
  }
}
