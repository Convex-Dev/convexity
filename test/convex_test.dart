import 'dart:convert' as convert;

import 'package:flutter_test/flutter_test.dart';
import 'package:convex_wallet/convex.dart' as convex;

var _heroAddress =
    '7E66429CA9c10e68eFae2dCBF1804f0F6B3369c7164a3187D6233683c258710f';

void main() {
  group('Query - Convex Lisp', () {
    test('Inc', () async {
      var response = await convex.query(
          scheme: 'http',
          host: '127.0.0.1',
          port: 8080,
          source: '(inc 1)',
          address: _heroAddress);

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': 2});
    });

    test('Self Address', () async {
      var response = await convex.query(
          scheme: 'http',
          host: '127.0.0.1',
          port: 8080,
          source: '*address*',
          address: _heroAddress);

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': '0x' + _heroAddress});
    });
  });

  group('Query - Convex Scrypt', () {
    test('Inc', () async {
      var response = await convex.query(
          scheme: 'http',
          host: '127.0.0.1',
          port: 8080,
          source: 'inc(1)',
          lang: convex.Lang.convexScript,
          address: _heroAddress);

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': 2});
    });

    test('Self Address', () async {
      var response = await convex.query(
          scheme: 'http',
          host: '127.0.0.1',
          port: 8080,
          source: '_address_',
          lang: convex.Lang.convexScript,
          address: _heroAddress);

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': '0x' + _heroAddress});
    });
  });
}
