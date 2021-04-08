import 'package:decimal/decimal.dart';

Decimal decimal(String value) => Decimal.parse(value);

enum CvxUnit {
  copper,
  bronze,
  silver,
  gold,
}

int cvxUnitDecimals(CvxUnit unit) {
  switch (unit) {
    case CvxUnit.copper:
      return 0;
    case CvxUnit.bronze:
      return 3;
    case CvxUnit.silver:
      return 6;
    case CvxUnit.gold:
      return 9;
  }
}

Decimal shift(x, int decimals) {
  if (decimals.isNegative) {
    return decimal(x.toString()) / Decimal.fromInt(10).pow(-decimals);
  } else {
    return decimal(x.toString()) * Decimal.fromInt(10).pow(decimals);
  }
}

Decimal copperTo(int coins, {required CvxUnit toUnit}) =>
    shift(coins, cvxUnitDecimals(toUnit) * -1);

int toCopper(Decimal coins, {required CvxUnit fromUnit}) =>
    shift(coins, cvxUnitDecimals(fromUnit)).toInt();

Decimal price(
  double x, {
  required int ofTokenDecimals,
  required int withTokenDecimals,
}) =>
    shift(x, ofTokenDecimals - withTokenDecimals);
