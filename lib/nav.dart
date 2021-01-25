import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';

import 'convex.dart' as convex;
import 'model.dart';
import 'route.dart' as route;

void pushLauncher(BuildContext context) => Navigator.pushReplacementNamed(
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

Future<dynamic> pushAsset(
  BuildContext context, {
  AAsset aasset,
  Future balance,
}) =>
    Navigator.pushNamed(
      context,
      route.asset,
      arguments: Tuple2(aasset, balance),
    );

void pushFollow(BuildContext context) => Navigator.pushNamed(
      context,
      route.follow,
    );

Future<dynamic> pushFungibleTransfer(
  BuildContext context,
  convex.FungibleToken token,
  Future<dynamic> balance,
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

Future<dynamic> pushNewToken(BuildContext context) => Navigator.pushNamed(
      context,
      route.newToken,
    );

Future<dynamic> pushNewNonFungibleToken(
  BuildContext context, {
  convex.NonFungibleToken nonFungibleToken,
}) =>
    Navigator.pushNamed(
      context,
      route.newNonFungibleToken,
      arguments: nonFungibleToken,
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
      arguments: params ?? SelectAccountParams(),
    );

Future<dynamic> pushNewContact(BuildContext context) => Navigator.pushNamed(
      context,
      route.newContact,
    );

Future<dynamic> pushWhitelist(BuildContext context) => Navigator.pushNamed(
      context,
      route.whitelist,
    );

Future<dynamic> pushNewWhitelist(BuildContext context) => Navigator.pushNamed(
      context,
      route.addWhitelist,
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

Future<dynamic> pushNonFungibleTransfer(
  BuildContext context, {
  convex.NonFungibleToken nonFungibleToken,
  int tokenId,
}) =>
    Navigator.pushNamed(
      context,
      route.nonFungibleTransfer,
      arguments: Tuple2(
        nonFungibleToken,
        tokenId,
      ),
    );

Future<dynamic> pushActivity(
  BuildContext context, {
  @required Activity activity,
}) =>
    Navigator.pushNamed(
      context,
      route.activity,
      arguments: activity,
    );

Future<dynamic> pushStaking(BuildContext context) => Navigator.pushNamed(
      context,
      route.staking,
    );
