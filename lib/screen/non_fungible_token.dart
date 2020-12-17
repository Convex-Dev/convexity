import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../widget.dart';
import '../convex.dart';

class NonFungibleTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Tuple2<NonFungibleToken, dynamic> t =
        ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Non-Fungible Token')),
      body: NonFungibleTokenScreenBody(t.item1),
    );
  }
}

class NonFungibleTokenScreenBody extends StatefulWidget {
  final NonFungibleToken nonFungibleToken;

  const NonFungibleTokenScreenBody(
    this.nonFungibleToken, {
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NonFungibleTokenScreenBodyState();
}

class _NonFungibleTokenScreenBodyState
    extends State<NonFungibleTokenScreenBody> {
  @override
  Widget build(BuildContext context) => Container(
        padding: defaultScreenPadding,
        child: Text('NFT'),
      );
}
