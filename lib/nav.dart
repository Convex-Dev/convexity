import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';

import 'convex.dart' as convex;
import 'model.dart';
import 'route.dart' as route;

void pushLauncher(BuildContext context) => Navigator.pushNamed(
      context,
      route.launcher,
    );

void pushAccount(BuildContext context, convex.Address address) =>
    Navigator.pushNamed(
      context,
      route.account,
      arguments: address,
    );

void pushSettings(BuildContext context) => Navigator.pushNamed(
      context,
      route.settings,
    );

void pushTransfer(BuildContext context) => Navigator.pushNamed(
      context,
      route.transfer,
    );

void pushAssets(BuildContext context) => Navigator.pushNamed(
      context,
      route.assets,
    );

Future<dynamic> pushAsset(BuildContext context, AAsset aasset) =>
    Navigator.pushNamed(
      context,
      route.asset,
      arguments: aasset,
    );

void pushFollow(BuildContext context) => Navigator.pushNamed(
      context,
      route.follow,
    );

Future<dynamic> pushFungibleTransfer(
  BuildContext context,
  convex.FungibleToken token,
  Future<int> balance,
) =>
    Navigator.pushNamed(
      context,
      route.fungibleTransfer,
      arguments: Tuple2(token, balance),
    );

void pushMyTokens(BuildContext context) => Navigator.pushNamed(
      context,
      route.myTokens,
    );

void pushNewToken(BuildContext context) => Navigator.pushNamed(
      context,
      route.newToken,
    );

Future<dynamic> pushAddressBook(BuildContext context) => Navigator.pushNamed(
      context,
      route.addressBook,
    );

Future<dynamic> pushSelectAccount(
  BuildContext context, {
  SelectAccountParams params,
}) =>
    Navigator.pushNamed(
      context,
      route.selectAccount,
      arguments: params,
    );

Future<dynamic> pushNewContact(BuildContext context) => Navigator.pushNamed(
      context,
      route.newContact,
    );

Future<dynamic> pushNonFungibleToken(
  BuildContext context, {
  convex.NonFungibleToken nonFungibleToken,
  int tokenId,
  Future<convex.Result> data,
}) =>
    Navigator.pushNamed(
      context,
      route.nonFungibleToken,
      arguments: Tuple3(
        nonFungibleToken,
        tokenId,
        data,
      ),
    );
