import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'convex.dart';

String showDecimals(int num, int decimals) {
  if ((decimals < 1) || (decimals > 12)) throw ("Decimals out of range");

  if (num < 0) throw ("Negative number");

  int divisor = pow(10, decimals);
  int x = num ~/ divisor;
  int y = num % divisor;

  return x.toString() +
      '.' +
      NumberFormat("000000000000".substring(0, decimals), null).format(y);
}

String formatFungibleCurrency({
  @required FungibleTokenMetadata metadata,
  @required int number,
}) =>
    metadata.currencySymbol +
    (metadata.decimals == 0
        ? number.toString()
        : showDecimals(number, metadata.decimals));

String defaultDateTimeFormat(DateTime x) => DateFormat('d/M/y H:m:s').format(x);
