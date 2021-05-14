import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:tuple/tuple.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../widget.dart';
import '../convex.dart';
import '../nav.dart';
import '../shop.dart' as shop;
import '../format.dart' as format;
import '../currency.dart' as currency;

String? _nonFungibleName(Map<String, dynamic>? data) =>
    data == null ? null : data['name'] as String;

String? _nonFungibleUri(Map<String, dynamic>? data) =>
    data == null ? null : data['uri'] as String;

class NonFungibleTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Tuple of NFT + Token ID + Data.
    final Tuple3<NonFungibleToken, int, Future<Result>> t =
        ModalRoute.of(context)!.settings.arguments
            as Tuple3<NonFungibleToken, int, Future<Result>>;

    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(title: Text('Non-Fungible Token')),
        body: Container(
          padding: defaultScreenPadding,
          child: NonFungibleTokenScreenBody(
            nonFungibleToken: t.item1,
            tokenId: t.item2,
            data: t.item3,
          ),
        ),
      ),
      onWillPop: () async {
        Navigator.of(context).pop(true);

        return false;
      },
    );
  }
}

class NonFungibleTokenScreenBody extends StatefulWidget {
  final NonFungibleToken nonFungibleToken;
  final int tokenId;
  final Future<Result> data;

  const NonFungibleTokenScreenBody({
    Key? key,
    required this.nonFungibleToken,
    required this.tokenId,
    required this.data,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NonFungibleTokenScreenBodyState();
}

class _NonFungibleTokenScreenBodyState
    extends State<NonFungibleTokenScreenBody> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result>(
      future: widget.data,
      builder: (context, snapshot) {
        return ListView(
          children: [
            ListTile(
              title: Text('ID'),
              subtitle: Text(widget.tokenId.toString()),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              Center(
                child: CircularProgressIndicator(),
              )
            else if (snapshot.hasError)
              ListTile(
                leading: Icon(Icons.error),
                title: Text(
                  'Sorry. It was not possible to query data for this token.',
                ),
              )
            else ...[
              ListTile(
                title: Text('Name'),
                subtitle: Text(
                  _nonFungibleName(snapshot.data?.value) ?? 'No name',
                ),
              ),
              _nonFungibleUri(snapshot.data?.value) == null
                  ? Image.memory(kTransparentImage)
                  : FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: _nonFungibleUri(snapshot.data?.value)!,
                    ),
              Gap(20),
              SizedBox(
                height: defaultButtonHeight,
                child: ElevatedButton(
                  child: Text('Offer for Sale...'),
                  onPressed: () {
                    _sell(context, data: snapshot.data?.value);
                  },
                ),
              ),
              Gap(10),
              SizedBox(
                height: defaultButtonHeight,
                child: ElevatedButton(
                  child: Text('Transfer'),
                  onPressed: () {
                    pushNonFungibleTransfer(
                      context,
                      nonFungibleToken: widget.nonFungibleToken,
                      tokenId: widget.tokenId,
                    );
                  },
                ),
              ),
            ]
          ],
        );
      },
    );
  }

  void _sell(BuildContext context, {Map<String, dynamic>? data}) async {
    final shop.NewListing? newListing = await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 260,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: _NonFungibleSell(
            nonFungibleToken: widget.nonFungibleToken,
            tokenId: widget.tokenId,
            data: data,
          ),
        ),
      ),
    );

    if (newListing == null) return;

    final appState = context.read<AppState>();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 260,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: FutureBuilder(
            future: shop.addListing(
              convexClient: appState.convexClient(),
              newListing: newListing,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(
                  child: CircularProgressIndicator(),
                );

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check,
                    size: 80,
                    color: Colors.green,
                  ),
                  Gap(10),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Your listing is now available in the Shop.'),
                  ),
                  Gap(20),
                  ElevatedButton(
                    child: Text('Done'),
                    onPressed: () {
                      // Pop Modal.
                      Navigator.pop(context);
                      // Pop NFT.
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NonFungibleSell extends StatefulWidget {
  final NonFungibleToken nonFungibleToken;
  final int tokenId;
  final Map<String, dynamic>? data;

  const _NonFungibleSell(
      {Key? key,
      required this.nonFungibleToken,
      required this.tokenId,
      required this.data})
      : super(key: key);

  @override
  _NonFungibleSellState createState() => _NonFungibleSellState();
}

class _NonFungibleSellState extends State<_NonFungibleSell> {
  String? _price;
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

    return Column(
      children: [
        Text(
          'Set sale price for NFT',
          style: Theme.of(context).textTheme.headline5,
        ),
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
                  setState(() {
                    _price = value;
                  });
                },
              ),
            ),
            Gap(10),
            FutureBuilder<Set<AAsset>?>(
              future: _assets,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 59,
                    child: Center(
                      child: Spinner(),
                    ),
                  );
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
                      (a, b) => a.metadata.tickerSymbol
                          .compareTo(b.metadata.tickerSymbol),
                    ),
                  itemWidget: (FungibleToken token) {
                    return Text(token.metadata.tickerSymbol);
                  },
                  onChanged: (t) {
                    setState(() {
                      _token = t == CVX ? null : t;
                    });
                  },
                );
              },
            ),
          ],
        ),
        Gap(40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Gap(20),
            ElevatedButton(
              child: Text('Offer for Sale!'),
              onPressed: (_price ?? '').isEmpty
                  ? null
                  : () {
                      Tuple2<Address, int> asset = Tuple2(
                        widget.nonFungibleToken.address,
                        widget.tokenId,
                      );

                      // If price is in Tokens, amount needs to be read
                      // considering decimal places.
                      // If price is in CVX, it needs to be converted to Copper.
                      Tuple2<int, Address?> price = Tuple2(
                        _token == null
                            ? currency.toCopper(
                                currency.decimal(_price ?? '0'),
                                fromUnit: currency.CvxUnit.gold,
                              )
                            : format.readFungibleCurrency(
                                metadata: _token!.metadata,
                                s: _price ?? '0',
                              ),
                        _token?.address,
                      );

                      final newListing = shop.NewListing(
                        description: _nonFungibleName(widget.data) ??
                            'Listing for ${asset.item1}',
                        asset: asset,
                        price: price,
                        image: _nonFungibleUri(widget.data),
                      );

                      Navigator.pop(context, newListing);
                    },
            ),
          ],
        ),
      ],
    );
  }
}
