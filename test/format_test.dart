import 'package:flutter_test/flutter_test.dart';

import '../lib/format.dart' as format;

void main() {
  test('Format integer part', () {
    expect(format.formatIntegerPart(1), '1');
    expect(format.formatIntegerPart(1000), '1,000');
    expect(format.formatIntegerPart(1000000), '1,000,000');
  });

  test('Format with decimals', () {
    expect(() => format.formatWithDecimals(1, 0), throwsFormatException);
    expect(() => format.formatWithDecimals(1, 13), throwsFormatException);

    expect(format.formatWithDecimals(1, 1), '0.1');
    expect(format.formatWithDecimals(1, 5), '0.00001');
  });

  test('Read with decimals', () {
    expect(format.readWithDecimals('1000', 0), 1000);
    expect(format.readWithDecimals('1000', 1), 10000);
    expect(format.readWithDecimals('1000', 2), 100000);
    expect(format.readWithDecimals('1000', 3), 1000000);
  });
}
