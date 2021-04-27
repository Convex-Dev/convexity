import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../convex.dart';
import '../model.dart';
import '../shop.dart' as shop;
import '../widget.dart' as widget;
import '../route.dart' as route;
import '../format.dart' as format;

class ListingScreen extends StatefulWidget {
  final shop.Listing? listing;

  const ListingScreen({Key? key, this.listing}) : super(key: key);

  @override
  _ListingScreenState createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  Future<AAsset?>? _fungible;

  @override
  Widget build(BuildContext context) {
    final shop.Listing _listing =
        ModalRoute.of(context)!.settings.arguments as shop.Listing;

    if (_listing.price.item2 != null) {
      setState(() {
        _fungible = context
            .read<AppState>()
            .convexityClient()
            .asset(_listing.price.item2!);
      });
    }

    final appState = context.read<AppState>();

    final isOwnerSelf = _listing.owner == appState.model.activeAddress;

    final Future<AAsset?>? aasset = _listing.price.item2 != null
        ? context
            .watch<AppState>()
            .convexityClient()
            .asset(_listing.price.item2!)
        : null;

    final Widget priceWidget = aasset == null
        ? Text(
            '${shop.priceStr(_listing.price)} CVX',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white),
          )
        : FutureBuilder<AAsset?>(
            future: aasset,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Getting price...');
              }

              FungibleTokenMetadata metadata = snapshot.data?.asset.metadata;

              return Text(
                '${format.formatFungibleCurrency(metadata: metadata, number: _listing.price.item1)} ${metadata.tickerSymbol}',
                overflow: TextOverflow.ellipsis,
              );
            },
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _listing.description,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Container(
        padding: widget.defaultScreenPadding,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (_listing.image != null)
                      FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: _listing.image!,
                      ),
                    ListTile(
                      title: Text(
                        'Price',
                      ),
                      subtitle: priceWidget,
                    ),
                    ListTile(
                      title: Text(
                        'Description',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_listing.description),
                    ),
                    ListTile(
                      title: Text(
                        'Seller',
                      ),
                      subtitle: Text(_listing.owner.toString()),
                    ),
                    ListTile(
                      title: Text(
                        'Asset',
                      ),
                      subtitle: Text(
                          '${_listing.asset.item1}, ${_listing.asset.item2}'),
                    ),
                    ListTile(
                      title: Text(
                        'Listing ID',
                      ),
                      subtitle: Text(_listing.id.toString()),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: widget.defaultButtonHeight,
                width: double.infinity,
                child: ElevatedButton(
                  child: Text(isOwnerSelf ? 'Remove Listing' : 'Buy'),
                  onPressed: () {
                    _confirm(
                      context,
                      listing: _listing,
                      isOwnerSelf: isOwnerSelf,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm(
    BuildContext context, {
    required shop.Listing listing,
    required bool isOwnerSelf,
  }) async {
    bool? confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) {
        final Widget priceWidget = _fungible == null
            ? Text(
                '${shop.priceStr(listing.price)} CVX',
                overflow: TextOverflow.ellipsis,
              )
            : FutureBuilder<AAsset?>(
                future: _fungible,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'Getting price...',
                      overflow: TextOverflow.ellipsis,
                    );
                  }

                  FungibleTokenMetadata metadata =
                      snapshot.data?.asset.metadata;

                  return Text(
                    '${format.formatFungibleCurrency(metadata: metadata, number: listing.price.item1)} ${metadata.tickerSymbol}',
                    overflow: TextOverflow.ellipsis,
                  );
                },
              );

        return SingleChildScrollView(
          child: Container(
            height: 260,
            padding: EdgeInsets.only(top: 14),
            child: Column(
              children: [
                Icon(
                  Icons.help,
                  size: 80,
                  color: Colors.black12,
                ),
                Gap(5),
                Text(
                  isOwnerSelf
                      ? 'Please confirm.'
                      : 'Please confirm your purchase.',
                  style: Theme.of(context).textTheme.caption,
                ),
                Gap(10),
                if (isOwnerSelf)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remove ',
                      ),
                      Text(
                        '${listing.description}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '?',
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Buy ',
                      ),
                      Text(
                        '${listing.description}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' for ',
                      ),
                      priceWidget,
                      Text(
                        '${listing.price.item2 == null ? 'CVX' : ''}?',
                      ),
                    ],
                  ),
                Gap(20),
                ElevatedButton(
                  child: Text('Confirm'),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    final appState = context.read<AppState>();

    if (confirmation == true) {
      final Future result = isOwnerSelf
          ? shop.removeListing(appState.convexClient(), id: listing.id)
          : shop.buyListing(appState.convexClient(), listing: listing);

      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: 300,
            child: FutureBuilder(
              future: result,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(
                    child: CircularProgressIndicator(),
                  );

                if (snapshot.hasError) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error,
                          size: 80,
                          color: Colors.black12,
                        ),
                        Gap(20),
                        Text(snapshot.error.toString()),
                        Gap(20),
                        ElevatedButton(
                          child: Text('Okay'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ),
                  );
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        size: 80,
                        color: Colors.black12,
                      ),
                      Gap(20),
                      Text(isOwnerSelf
                          ? 'Successfully removed listing.'
                          : 'Congratulations! You have successfully bought the asset.'),
                      Gap(20),
                      ElevatedButton(
                        child: Text('Okay'),
                        onPressed: () {
                          Navigator.popUntil(
                            context,
                            ModalRoute.withName(route.SHOP),
                          );
                        },
                      )
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }
}
