import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../widget.dart';

Widget nonFungibleTransferScreen({
  NonFungibleToken nonFungibleToken,
  int tokenId,
}) =>
    StatelessWidgetBuilder((context) {
      var arguments = ModalRoute.of(context).settings.arguments
          as Tuple2<NonFungibleToken, int>;

      // Token can be passed directly to the constructor,
      // or via Navigator arguments.
      var _nonFungibleToken = nonFungibleToken ?? arguments.item1;
      var _tokenId = tokenId ?? arguments.item2;

      return Scaffold(
        appBar: AppBar(
          title: Text('Transfer Non-Fungible $_tokenId'),
        ),
        body: Container(
          padding: defaultScreenPadding,
          child: Text('NFT'),
        ),
      );
    });
