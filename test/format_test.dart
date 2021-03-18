import 'package:flutter_test/flutter_test.dart';

import '../lib/format.dart' as format;

void main() {
  test('Market Price precision', () {
    expect(format.marketPriceStr(1000), '1000.0');
    expect(format.marketPriceStr(0.00001), '0.000010000');
  });
}
