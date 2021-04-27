import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../model.dart';
import '../shop.dart' as shop;
import '../widget.dart' as widget;
import '../route.dart' as route;

class ListingScreen extends StatelessWidget {
  final shop.Listing? listing;

  const ListingScreen({Key? key, this.listing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shop.Listing _listing =
        listing ?? ModalRoute
            .of(context)!
            .settings
            .arguments as shop.Listing;

    final appState = context.read<AppState>();

    final isOwnerSelf = _listing.owner == appState.model.activeAddress;

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
                        'ID',
                      ),
                      subtitle: Text(_listing.id.toString()),
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
                        'Asset',
                      ),
                      subtitle: Text(
                          '${_listing.asset.item1}, ${_listing.asset.item2}'),
                    ),
                    ListTile(
                      title: Text(
                        'Owner',
                      ),
                      subtitle: Text(_listing.owner.toString()),
                    ),
                    ListTile(
                      title: Text(
                        'Price',
                      ),
                      subtitle: Text(
                        '${shop.priceStr(_listing.price)}'
                            '${_listing.price.item2 ?? ' CVX'}',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: widget.defaultButtonHeight,
                width: double.infinity,
                child: ElevatedButton(
                  child: Text(isOwnerSelf ? 'Remove' : 'Buy'),
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

  void _confirm(BuildContext context, {
    required shop.Listing listing,
    required bool isOwnerSelf,
  }) async {
    bool? confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) {
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
                  'Please confirm your purchase.',
                  style: Theme
                      .of(context)
                      .textTheme
                      .caption,
                ),
                Gap(5),
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
                    Text(
                      '${listing.price.item1} ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
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
      if (isOwnerSelf) {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              height: 300,
              child: FutureBuilder(
                future:
                shop.removeListing(appState.convexClient(), id: listing.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(
                      child: CircularProgressIndicator(),
                    );

                  return Center(
                    child: ElevatedButton(
                      child: Text('Done'),
                      onPressed: () {
                        Navigator.popUntil(
                          context,
                          ModalRoute.withName(route.SHOP),
                        );
                      },
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
}
