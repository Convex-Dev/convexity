import 'package:decimal/decimal.dart';

enum CvxUnit {
  copper,
  bronze,
  silver,
  gold,
}

Decimal decimal(String value) => Decimal.parse(value);

int unitDecimals(CvxUnit unit) {
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

Decimal copperTo(int coins, CvxUnit unit) =>
    shift(coins, unitDecimals(unit) * -1);

int toCopper(Decimal coins, CvxUnit unit) =>
    shift(coins, unitDecimals(unit)).toInt();
