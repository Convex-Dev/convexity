import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:tuple/tuple.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../widget.dart';
import '../convex.dart';
import '../nav.dart';
import '../config.dart' as config;

class NonFungibleTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Tuple of NFT + ID + Data.
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
  Widget build(BuildContext context) => ListView(
        children: [
          ListTile(
            title: Text(widget.tokenId.toString()),
            subtitle: Text('ID'),
          ),
          FutureBuilder<Result>(
            future: widget.data,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // Result value is a map of attribute name to value - unless there's an error.
                if (snapshot.data!.errorCode != null) {
                  return ListTile(
                    leading: Icon(Icons.error),
                    title: Text(
                      'Sorry. It was not possible to query data for this token.',
                    ),
                  );
                }

                return ListTile(
                  title: Text(snapshot.data!.value['name']),
                  subtitle: Text('Name'),
                );
              }

              return Center(child: CircularProgressIndicator());
            },
          ),
          FutureBuilder<Result>(
            future: widget.data,
            builder: (context, snapshot) {
              final imageTransparent = Image.memory(kTransparentImage);

              if (snapshot.hasData) {
                if (snapshot.data!.errorCode != null) {
                  return imageTransparent;
                }

                if (snapshot.data!.value['uri'] == null) {
                  return imageTransparent;
                }

                if (Uri.parse(snapshot.data!.value['uri']).isAbsolute ==
                    false) {
                  return imageTransparent;
                }

                return FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: snapshot.data!.value['uri'],
                );
              }

              return imageTransparent;
            },
          ),
          // ElevatedButton(
          //   child: Text('Sell'),
          //   onPressed: () {
          //     _sell(context);
          //   },
          // ),
          ElevatedButton(
            child: Text('Transfer'),
            onPressed: () {
              pushNonFungibleTransfer(
                context,
                nonFungibleToken: widget.nonFungibleToken,
                tokenId: widget.tokenId,
              );
            },
          ),
        ],
      );

  void _sell(BuildContext context) async {
    final Tuple2<String, FungibleToken?>? price = await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 260,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: _NonFungibleSell(
            nonFungibleToken: widget.nonFungibleToken,
            tokenId: widget.tokenId,
            data: widget.data,
          ),
        ),
      ),
    );

    if (price == null) return;

    final appState = context.read<AppState>();

    final listing = '{'
        ' :asset [${widget.nonFungibleToken.address} ${widget.tokenId}]'
        ' :price ${price.item1}'
        ' :price-with ${price.item2?.address ?? 'nil'}'
        '}';

    final Future<Result> transaction = appState
        .convexClient()
        .transact(source: '(call ${config.NFT_SHOP_ADDRESS} (sell $listing))');

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 260,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: FutureBuilder(
            future: transaction,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(
                  child: CircularProgressIndicator(),
                );

              return Center(
                child: ElevatedButton(
                  child: Text('Done'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
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
  final Future<Result> data;

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
          'Sell ',
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
                      (a, b) => a.metadata.tickerSymbol!
                          .compareTo(b.metadata.tickerSymbol!),
                    ),
                  itemWidget: (FungibleToken token) {
                    return Text(token.metadata.tickerSymbol!);
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
              child: Text('Sell'),
              onPressed: () {
                Navigator.pop(
                    context, Tuple2<String, FungibleToken?>(_price!, _token));
              },
            ),
          ],
        ),
      ],
    );
  }
}
