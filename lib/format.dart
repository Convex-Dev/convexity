import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatFungible({
  @required FungibleTokenMetadata metadata,
  @required int balance,
}) =>
    NumberFormat.simpleCurrency(
      name: metadata.symbol,
      decimalDigits: metadata.decimals,
    ).format(balance);
