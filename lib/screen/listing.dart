import 'package:flutter/material.dart';

import '../shop.dart' as shop;
import '../widget.dart' as widget;

class ListingScreen extends StatelessWidget {
  final shop.Listing? listing;

  const ListingScreen({Key? key, this.listing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shop.Listing _listing =
        listing ?? ModalRoute.of(context)!.settings.arguments as shop.Listing;

    return Scaffold(
      appBar: AppBar(title: Text('Listing')),
      body: Container(
        padding: widget.defaultScreenPadding,
        child: ListView(
          children: [
            ListTile(
              title: Text(
                '${_listing.id}',
              ),
              subtitle: Text('ID'),
            ),
            ListTile(
              title: Text(
                '${_listing.asset.item1}, ${_listing.asset.item2}',
              ),
              subtitle: Text('Asset'),
            ),
            ListTile(
              title: Text(
                '${_listing.price.item1}, ${_listing.price.item2 ?? ''}',
              ),
              subtitle: Text('Price'),
            ),
            ListTile(
              title: Text(
                '${_listing.owner}',
              ),
              subtitle: Text('Owner'),
            ),
            ElevatedButton(
              child: Text('Buy'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      height: 300,
                      child: Center(
                        child: ElevatedButton(
                          child: Text('Done'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
