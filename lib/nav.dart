import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'convex.dart' as convex;
import 'route.dart' as route;

void account(BuildContext context, convex.Address address) =>
    Navigator.pushNamed(
      context,
      route.account,
      arguments: address,
    );

void settings(BuildContext context) => Navigator.pushNamed(
      context,
      route.settings,
    );
