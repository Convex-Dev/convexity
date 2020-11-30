import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'convex.dart';

String formatFungibleCurrency({
  @required FungibleTokenMetadata metadata,
  @required int number,
}) =>
    NumberFormat.simpleCurrency(
      name: metadata.symbol,
      decimalDigits: metadata.decimals,
    ).format(number);
