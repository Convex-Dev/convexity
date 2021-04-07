import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/currency.dart' as currency;

void main() {
  test('Roundtrip Coins', () {
    currency.CvxUnit.values.forEach((unit) {
      final nums = <int>[
        0,
        -1,
        1,
        1000000000,
        -9223372036854775808,
        9223372036854775807,
      ];

      nums.forEach((coins) {
        final Decimal d = currency.copperTo(coins, unit);
        final int x = currency.toCopper(d, unit);

        expect(x, coins);
      });
    });
  });

  test('Shift decimal place', () {
    expect(currency.shift(1, -1), currency.decimal('0.1'));
    expect(currency.shift(1, 0), currency.decimal('1'));
    expect(currency.shift(1, 1), currency.decimal('10'));
  });

  group('Copper conversion', () {
    test('Copper to Copper', () {
      expect(
        currency.copperTo(1000, currency.CvxUnit.copper),
        currency.decimal('1000'),
      );
    });

    test('Copper to Bronze', () {
      expect(
        currency.copperTo(100, currency.CvxUnit.bronze),
        currency.decimal('0.1'),
      );

      expect(
        currency.copperTo(1000, currency.CvxUnit.bronze),
        currency.decimal('1'),
      );

      expect(
        currency.copperTo(1000000, currency.CvxUnit.bronze),
        currency.decimal('1000'),
      );
    });

    test('Copper to Silver', () {
      expect(
        currency.copperTo(1000, currency.CvxUnit.silver),
        currency.decimal('0.001'),
      );

      expect(
        currency.copperTo(1000000, currency.CvxUnit.silver),
        currency.decimal('1'),
      );
    });

    test('Copper to Gold', () {
      expect(
        currency.copperTo(-1, currency.CvxUnit.gold),
        currency.decimal('-0.000000001'),
      );

      expect(
        currency.copperTo(999999999999999999, currency.CvxUnit.gold),
        currency.decimal('999999999.999999999'),
      );

      expect(
        currency.copperTo(1000000, currency.CvxUnit.gold),
        currency.decimal('0.001'),
      );

      expect(
        currency.copperTo(1000000000, currency.CvxUnit.gold),
        currency.decimal('1'),
      );
    });
  });
}
