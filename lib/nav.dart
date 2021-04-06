import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';
import 'package:provider/provider.dart';

import 'convex.dart' as convex;
import 'model.dart';
import 'route.dart' as route;
import 'widget.dart';

Future<dynamic> pushLauncher(BuildContext context) =>
    Navigator.pushReplacementNamed(
      context,
      route.LAUNCHER,
    );

Future<dynamic> pushAccount(BuildContext context, convex.Address address) =>
    Navigator.pushNamed(
      context,
      route.ACCOUNT,
      arguments: address,
    );

Future<dynamic> pushAccount2(BuildContext context, convex.Address? address) =>
    Navigator.pushNamed(
      context,
      route.ACCOUNT,
      arguments: address,
    );

Future<dynamic> pushSettings(BuildContext context) => Navigator.pushNamed(
      context,
      route.SETTINGS,
    );

Future<dynamic> pushTransfer(BuildContext context) => Navigator.pushNamed(
      context,
      route.TRANSFER,
    );

Future<dynamic> pushAssets(BuildContext context) => Navigator.pushNamed(
      context,
      route.ASSETS,
    );

Future<dynamic> pushAsset(
  BuildContext context, {
  AAsset? aasset,
  Future? balance,
}) =>
    Navigator.pushNamed(
      context,
      route.ASSET,
      arguments: Tuple2(aasset, balance),
    );

Future<dynamic> pushFollow(BuildContext context) => Navigator.pushNamed(
      context,
      route.FOLLOW,
    );

Future<dynamic> pushFungibleTransfer(
  BuildContext context,
  convex.FungibleToken? token,
  Future<dynamic>? balance,
) =>
    Navigator.pushNamed(
      context,
      route.FUNGIBLE_TRANSFER,
      arguments: Tuple2(token, balance),
    );

Future<dynamic> pushMyTokens(BuildContext context) => Navigator.pushNamed(
      context,
      route.MY_TOKENS,
    );

Future<dynamic> pushNewToken(BuildContext context) => Navigator.pushNamed(
      context,
      route.NEW_TOKEN,
    );

Future<dynamic> pushNewNonFungibleToken(
  BuildContext context, {
  convex.NonFungibleToken? nonFungibleToken,
}) =>
    Navigator.pushNamed(
      context,
      route.NEW_NON_FUNGIBLE_TOKEN,
      arguments: nonFungibleToken,
    );

Future<dynamic> pushAddressBook(BuildContext context) => Navigator.pushNamed(
      context,
      route.ADDRESS_BOOK,
    );

Future<dynamic> pushSelectAccount(
  BuildContext context, {
  SelectAccountParams? params,
}) =>
    Navigator.pushNamed(
      context,
      route.SELECT_ACCOUNT,
      arguments: params ?? SelectAccountParams(),
    );

Future<dynamic> pushNewContact(BuildContext context) => Navigator.pushNamed(
      context,
      route.NEW_CONTACT,
    );

Future<dynamic> pushWhitelist(BuildContext context) => Navigator.pushNamed(
      context,
      route.WHITELIST,
    );

Future<dynamic> pushNewWhitelist(BuildContext context) => Navigator.pushNamed(
      context,
      route.ADD_WHITELIST,
    );

Future<dynamic> pushNonFungibleToken(
  BuildContext context, {
  convex.NonFungibleToken? nonFungibleToken,
  int? tokenId,
  Future<convex.Result>? data,
}) =>
    Navigator.pushNamed(
      context,
      route.NON_FUNGIBLE_TOKEN,
      arguments: Tuple3(
        nonFungibleToken,
        tokenId,
        data,
      ),
    );

Future<dynamic> pushNonFungibleTransfer(
  BuildContext context, {
  convex.NonFungibleToken? nonFungibleToken,
  int? tokenId,
}) =>
    Navigator.pushNamed(
      context,
      route.NON_FUNGIBLE_TRANSFER,
      arguments: Tuple2(
        nonFungibleToken,
        tokenId,
      ),
    );

Future<dynamic> pushActivity(
  BuildContext context, {
  required Activity activity,
}) =>
    Navigator.pushNamed(
      context,
      route.ACTIVITY,
      arguments: activity,
    );

Future<dynamic> pushStaking(BuildContext context) => Navigator.pushNamed(
      context,
      route.STAKING,
    );

Future<dynamic> pushStakingPeer(
  BuildContext context, {
  Peer? peer,
}) =>
    Navigator.pushNamed(
      context,
      route.STAKING_PEER,
      arguments: peer,
    );

Future<dynamic> pushExchange(
  BuildContext context, {
  required ExchangeParams params,
}) {
  final defaultWithToken = context.read<AppState>().model.defaultWithToken;

  // Use default 'with Token' if it's not specified in the parameters,
  // and it's not the same as 'of Token'.
  final withToken =
      params.withToken == null && params.ofToken != defaultWithToken
          ? defaultWithToken
          : null;

  return Navigator.pushNamed(
    context,
    route.EXCHANGE,
    arguments: withToken != null
        ? params.copyWith2(withToken: () => defaultWithToken)
        : params,
  );
}

Future<dynamic> pushSelectFungible(BuildContext context) => Navigator.pushNamed(
      context,
      route.SELECT_FUNGIBLE,
    );

Future<dynamic> pushTopTokens(BuildContext context) => Navigator.pushNamed(
      context,
      route.TOP_TOKENS,
    );
