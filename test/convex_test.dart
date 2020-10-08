import 'dart:convert' as convert;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:convex_wallet/convex.dart' as convex;

var _heroAddress =
    '7E66429CA9c10e68eFae2dCBF1804f0F6B3369c7164a3187D6233683c258710f';

void main() {
  group('Query', () {
    test('Inc', () async {
      var client = http.Client();

      var response =
          await convex.query(client, source: '(inc 1)', address: _heroAddress);

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': 2});

      client.close();
    });

    test('Self Address', () async {
      var client = http.Client();

      var response = await convex.query(client,
          source: '*address*', address: _heroAddress);

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body), {'value': '0x' + _heroAddress});

      client.close();
    });
  });
}
