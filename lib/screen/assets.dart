import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';

import '../convex.dart' as convex;
import '../backend.dart' as backend;

class AssetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assets')),
      body: AssetsScreenBody(),
    );
  }
}

class AssetsScreenBody extends StatefulWidget {
  @override
  _AssetsScreenBodyState createState() => _AssetsScreenBodyState();
}

class _AssetsScreenBodyState extends State<AssetsScreenBody> {
  convex.Result result;

  final A = [
    FungibleToken(name: 'T1', balance: 10),
    FungibleToken(name: 'T2', balance: 5),
    NonFungibleToken(name: 'NFT1', coll: []),
    FungibleToken(name: 'T2', balance: 5),
    NonFungibleToken(name: 'NFT1', coll: []),
    FungibleToken(name: 'T1', balance: 10),
    FungibleToken(name: 'T2', balance: 5),
    NonFungibleToken(name: 'NFT1', coll: []),
    FungibleToken(name: 'T2', balance: 5),
    NonFungibleToken(name: 'NFT1', coll: []),
    FungibleToken(name: 'T2', balance: 5),
    NonFungibleToken(name: 'NFT1', coll: []),
    FungibleToken(name: 'T1', balance: 10),
    FungibleToken(name: 'T2', balance: 5),
    NonFungibleToken(name: 'NFT1', coll: []),
    FungibleToken(name: 'T2', balance: 5),
    NonFungibleToken(name: 'NFT1', coll: []),
  ];

  @override
  void initState() {
    super.initState();

    var convexityAddress =
        '581C366197D3f2016755d3D120068803dfb3781E7fed3A05F8369DE2a7dAcAD8';

    backend.queryAssets(convexityAddress).then((value) => print(value));
  }

  @override
  Widget build(BuildContext context) {
    print('${result?.value} ${result?.value.runtimeType}');

    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      children: A
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              token.name,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Gap(10),
            Column(
              children: [
                Text(
                  'BALANCE',
                  style: Theme.of(context).textTheme.overline,
                ),
                Text(
                  token.balance.toString(),
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
