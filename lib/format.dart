import 'package:flutter/material.dart';
import 'convex.dart';

String formatFungibleCurrency({
  @required FungibleTokenMetadata metadata,
  @required int number,
}) =>
    '${metadata.currencySymbol}${number.toStringAsFixed(metadata.decimals)}';
