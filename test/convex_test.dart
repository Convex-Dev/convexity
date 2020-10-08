import 'dart:convert' as convert;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:convex_wallet/convex.dart' as convex;

const _HERO_ADDRESS =
    '7E66429CA9c10e68eFae2dCBF1804f0F6B3369c7164a3187D6233683c258710f';

Future<http.Response> _query({
  String address = _HERO_ADDRESS,
  String source,
  convex.Lang lang = convex.Lang.convexLisp,
}) =>
    convex.query(
      scheme: 'http',
      host: '127.0.0.1',
      port: 8080,
      source: source,
      lang: lang,
      address: address,
    );

Future<http.Response> _account({
  String address = _HERO_ADDRESS,
}) =>
    convex.account(
      scheme: 'http',
      host: '127.0.0.1',
      port: 8080,
      address: address,
    );

void main() {
  group('Account', () {
    test('Details', () async {
      var response = await _account(address: _HERO_ADDRESS);

      Map body = convert.jsonDecode(response.body);

      expect(response.statusCode, 200);
      expect(body.keys.toSet(), {
        'environment',
        'address',
        'is_library',
        'is_actor',
        'memory_size',
        'balance',
        'allowance',
        'sequence',
        'type',
      });
    });

    test('Not found', () async {
      var response = await _account(
          address:
              '7E66429CA9c10e68eFae2dCBF1804f0F6B3369c7164a3187D6233683c258710d');

      expect(response.statusCode, 404);
    });
  });

  group('Query - Convex Lisp', () {
    test('Inc', () async {
      var response = await _query(source: '(inc 1)');

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': 2});
    });

    test('Self Address', () async {
      var response = await _query(source: '*address*');

      expect(response.statusCode, 200);
      expect(
          convert.jsonDecode(response.body), {'value': '0x' + _HERO_ADDRESS});
    });
  });

  group('Query - Convex Scrypt', () {
    test('Inc', () async {
      var response = await _query(
        source: 'inc(1)',
        lang: convex.Lang.convexScript,
      );

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': 2});
    });

    test('Self Address', () async {
      var response = await _query(
        source: '_address_',
        lang: convex.Lang.convexScript,
      );

      expect(response.statusCode, 200);
      expect(
          convert.jsonDecode(response.body), {'value': '0x' + _HERO_ADDRESS});
    });
  });
}
