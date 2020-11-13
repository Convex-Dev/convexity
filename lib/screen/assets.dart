import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flag/flag.dart';

import '../backend.dart' as backend;
import '../nav.dart' as nav;

class AssetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assets')),
      body: AssetsScreenBody(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => nav.pushNewAsset(context),
      ),
    );
  }
}

class AssetsScreenBody extends StatefulWidget {
  @override
  _AssetsScreenBodyState createState() => _AssetsScreenBodyState();
}

class _AssetsScreenBodyState extends State<AssetsScreenBody> {
  var isLoading = true;
  var assets = [];

  @override
  void initState() {
    super.initState();

    var convexityAddress =
        '33391329CBf87B84EdD482B04D7De6A7bC33Bb99B384D9d77B0365BD7a7e2562';

    backend.queryAssets(convexityAddress).then(
          (assets) => setState(
            () {
              this.isLoading = false;
              this.assets = assets;
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: assets
            .map(
              (token) => Container(
                padding: const EdgeInsets.all(8),
                child: AssetRenderer(token: token),
              ),
            )
            .toList(),
      );
    }
  }
}

class AssetRenderer extends StatelessWidget {
  final Token token;

  const AssetRenderer({Key key, @required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (token is FungibleToken) {
      return FungibleTokenRenderer(token: token);
    }

    return NonFungibleTokenRenderer(token: token);
  }
}

class FungibleTokenRenderer extends StatelessWidget {
  final FungibleToken token;

  const FungibleTokenRenderer({Key key, @required this.token})
      : super(key: key);

  String symbolToCountryCode(String symbol) {
    switch (symbol) {
      // Kuwait Dinar
      case 'KWD':
        return 'kw';
      // Bahrain Dinar
      case 'BHD':
        return 'bh';
      // Oman Rial
      case 'OMR':
        return 'om';
      // Jordan Dinar
      case 'JOD':
        return 'jo';
      // British Pound Sterling
      case 'GBP':
        return 'gb';
      // European Euro
      case 'EUR':
        return 'eu';
      // Swiss Franc
      case 'CHF':
        return 'ch';
      // US Dollar
      case 'USD':
        return 'us';
      case 'KYD':
        return 'ky';
      // Canadian Dollar
      case 'CAD':
        return 'ca';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flag(symbolToCountryCode(token.symbol), height: 20),
            Gap(10),
            Text(
              token.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Gap(8),
            Column(
              children: [
                Text(
                  'BALANCE',
                  style: Theme.of(context).textTheme.overline,
                ),
                Text(
                  '-',
                  style: Theme.of(context).textTheme.headline3,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class NonFungibleTokenRenderer extends StatelessWidget {
  final NonFungibleToken token;

  const NonFungibleTokenRenderer({Key key, @required this.token})
      : super(key: key);

  Widget tokenIdenticon() => SvgPicture.string(
        Jdenticon.toSvg('A'),
        width: 30,
        height: 30,
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(token.name),
            Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                tokenIdenticon(),
                tokenIdenticon(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
