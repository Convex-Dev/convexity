import 'dart:convert' as convert;

import 'package:convex_wallet/convex.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../lib/convex.dart' as convex;

const _TEST_ADDRESS =
    '7E66429CA9c10e68eFae2dCBF1804f0F6B3369c7164a3187D6233683c258710f';

Future<http.Response> _query({
  String address = _TEST_ADDRESS,
  String source,
  convex.Lang lang = convex.Lang.convexLisp,
}) =>
    convex.queryRaw(
      source: source,
      lang: lang,
      address: address,
    );

void main() {
  final convexClient = ConvexClient(
    server: convexWorldUri,
    client: http.Client(),
  );

  group('Convex Client', () {
    test('Create Account, check details, top up', () async {
      final generatedKeyPair = CryptoSign.randomKeys();

      final generatedAddress = await convexClient.createAccount(
        accountKey: AccountKey.fromBin(generatedKeyPair.pk),
      );

      expect(generatedAddress != null, true);

      final account = await convexClient.account2(address: generatedAddress);

      expect(account.type, AccountType.user);
      expect(account.address2, generatedAddress);

      final faucetResponse = await convexClient.faucet2(
        address: account.address2,
        amount: 1000000,
      );

      final faucetResponseBody = convert.jsonDecode(faucetResponse.body);

      expect(faucetResponse.statusCode, 200);
      expect(faucetResponseBody.keys.toSet(), {
        'address',
        'amount',
        'value',
      });
    });

    test('Prepare & Submit Transaction', () async {
      final prepareResponse = await convexClient.prepareTransaction2(
        address: Address2(9),
        source: '(inc 1)',
      );

      Map<String, dynamic> prepared = convert.jsonDecode(prepareResponse.body);

      expect(prepareResponse.statusCode, 200);
      expect(prepared.keys.toSet(), {
        'sequence',
        'address',
        'source',
        'lang',
        'hash',
      });

      final submitResponse = await convexClient.submitTransaction2(
        address: Address2(9),
        accountKey: AccountKey(''),
        hash: prepared['hash'],
        sig: '',
      );

      Map<String, dynamic> submitted = convert.jsonDecode(submitResponse.body);

      expect(submitResponse.statusCode, 400);
      expect(submitted['errorCode'], 'INCORRECT');
      expect(submitted['value'], 'Invalid signature.');
      expect(submitted['source'], 'Server');
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
        convert.jsonDecode(response.body),
        {'value': _TEST_ADDRESS},
      );
    });

    test('Error - UNDECLARED', () async {
      var response = await _query(source: '(incc 1)');

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body)['error-code'], 'UNDECLARED');
    });

    test('Error - CAST', () async {
      var response = await _query(source: '(map inc 1)');

      expect(response.statusCode, 200);
      expect(convert.jsonDecode(response.body)['error-code'], 'CAST');
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
      expect(convert.jsonDecode(response.body), {'value': _TEST_ADDRESS});
    });
  });
}
