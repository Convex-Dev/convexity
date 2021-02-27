import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';

import 'convex.dart';

final customNumberFormat = NumberFormat('#,###');

String formatIntegerPart(int n) => customNumberFormat.format(n);

String formatWithDecimals(int num, int decimals) {
  if ((decimals < 1) || (decimals > 12)) throw ("Decimals out of range");

  if (num < 0) throw ("Negative number");

  int divisor = pow(10, decimals);
  int x = num ~/ divisor;
  int y = num % divisor;

  return formatIntegerPart(x) +
      '.' +
      NumberFormat("000000000000".substring(0, decimals), null).format(y);
}

String formatFungibleCurrency({
  @required FungibleTokenMetadata metadata,
  @required int number,
}) =>
    metadata.currencySymbol +
    (metadata.decimals == 0
        ? formatIntegerPart(number)
        : formatWithDecimals(number, metadata.decimals));

int readWithDecimals(String s, int decimals) {
  // logger.d(
  //   'Set amount: $amountOf ' +
  //       '(Token decimals: ${params.ofToken.metadata.decimals}; ' +
  //       'amount = ${params.amount} * 10^${params.ofToken.metadata.decimals})',
  // );

  return (Decimal.parse(s) * Decimal.fromInt(pow(10, decimals))).toInt();
}

int readFungibleCurrency({
  @required FungibleTokenMetadata metadata,
  @required String s,
}) =>
    readWithDecimals(s, metadata.decimals);

String defaultDateTimeFormat(DateTime x) => DateFormat('d/M/y H:m:s').format(x);
