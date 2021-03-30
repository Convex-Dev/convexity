import 'dart:math';

import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';

import 'logger.dart';
import 'convex.dart';
import 'config.dart' as config;

final customNumberFormat = NumberFormat('#,###');

String formatIntegerPart(int? n) => customNumberFormat.format(n);

String formatWithDecimals(int num, int decimals) {
  if ((decimals < 1) || (decimals > 12)) throw ("Decimals out of range");

  if (num < 0) throw ("Negative number");

  int divisor = pow(10, decimals) as int;
  int x = num ~/ divisor;
  int y = num % divisor;

  return formatIntegerPart(x) +
      '.' +
      NumberFormat("000000000000".substring(0, decimals), null).format(y);
}

String formatFungibleCurrency({
  required FungibleTokenMetadata metadata,
  required int? number,
}) =>
    metadata.currencySymbol! +
    (metadata.decimals == 0
        ? formatIntegerPart(number)
        : formatWithDecimals(number!, metadata.decimals!));

int readWithDecimals(String s, int decimals) =>
    (Decimal.parse(s) * Decimal.fromInt(pow(10, decimals) as int)).toInt();

int readFungibleCurrency({
  required FungibleTokenMetadata metadata,
  required String s,
}) {
  try {
    return readWithDecimals(s, metadata.decimals!);
  } catch (e, s) {
    logger.e(s);

    rethrow;
  }
}

String formatCVX(int n) => formatWithDecimals(n, config.CVX_DECIMALS);

int readCVX(String s) => readWithDecimals(s, config.CVX_DECIMALS);

String defaultDateTimeFormat(DateTime x) => DateFormat('d/M/y H:m:s').format(x);

double shiftDecimalPlace(double x, int decimals) => x * pow(10, decimals);

double marketPrice({
  FungibleToken? ofToken,
  FungibleToken? withToken,
  required double price,
}) =>
    // A null 'of Token' or 'with Token' is interpreted as CVX.
    shiftDecimalPlace(
      price,
      (ofToken?.metadata.decimals ?? config.CVX_DECIMALS) -
          (withToken?.metadata.decimals ?? config.CVX_DECIMALS),
    );

String marketPriceStr(double price) => price.toStringAsPrecision(5);
