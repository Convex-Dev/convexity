import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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

void pushAsset(BuildContext context, AAsset aasset) => Navigator.pushNamed(
      context,
      route.asset,
      arguments: aasset,
    );

void pushFollow(BuildContext context) => Navigator.pushNamed(
      context,
      route.follow,
    );

void pushFungibleTransfer(
  BuildContext context,
  FungibleToken token,
  Future<int> balance,
) =>
    Navigator.pushNamed(
      context,
      route.fungibleTransfer,
      arguments: [token, balance],
    );
