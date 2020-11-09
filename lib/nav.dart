import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'convex.dart' as convex;
import 'route.dart' as route;

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
