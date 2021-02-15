import 'dart:convert' as convert;

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../lib/convex.dart';

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
      final result = await convexClient.query2(
        caller: Address2(9),
        source: '(inc 1)',
      );

      expect(result.value, 2);
    });

    test('Self Address', () async {
      final result = await convexClient.query2(
        caller: Address2(9),
        source: '*address*',
      );

      expect(result.value, 9);
    });

    test('Error - UNDECLARED', () async {
      final result = await convexClient.query2(
        caller: Address2(9),
        source: '(incc 1)',
      );

      expect(result.errorCode, 'UNDECLARED');
    });

    test('Error - CAST', () async {
      final result = await convexClient.query2(
        caller: Address2(9),
        source: '(map inc 1)',
      );

      expect(result.errorCode, 'CAST');
    });
  });

  group('Query - Convex Scrypt', () {
    test('Inc', () async {
      var result = await convexClient.query2(
        caller: Address2(9),
        source: 'inc(1)',
        lang: Lang.convexScript,
      );

      expect(result.value, 2);
    });

    test('Self Address', () async {
      final result = await convexClient.query2(
        caller: Address2(9),
        source: '_address_',
        lang: Lang.convexScript,
      );

      expect(result.value, 9);
    });
  });
}
