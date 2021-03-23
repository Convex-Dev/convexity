// REQUIREMENTS
// 'libsodium' must be installed on your lachine to be able to run these tests.
// On macOS: brew install libsodium

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

  group('Address', () {
    test('Address value', () {
      expect(Address(null).value, null);
      expect(Address(1).value, 1);
      expect(Address.fromStr('1').value, 1);
      expect(Address.fromStr(' 1').value, 1);
      expect(Address.fromStr('1 ').value, 1);
      expect(Address.fromStr('#1').value, 1);
      expect(Address.fromStr('# 1').value, 1);
      expect(Address.fromJson({'value': 1}).value, 1);

      // Error cases.
      expect(() => Address.fromStr('##1'), throwsFormatException);
      expect(() => Address.fromStr('#1#'), throwsFormatException);
      expect(() => Address.fromStr(''), throwsFormatException);
      expect(() => Address.fromStr('a'), throwsFormatException);
    });

    test('Address toString', () {
      expect(Address(1).toString(), '#1');
    });

    test('Address identity', () {
      expect(true, Address(1) == Address.fromStr('#1'));
    });

    test('Address toJson', () {
      expect(Address(1).toJson(), {'value': 1});
    });

    test('Address fromJson', () {
      expect(Address(1), Address.fromJson({'value': 1}));
    });
  });

  group('AccountKey', () {
    test('AccountKey value', () {
      expect(AccountKey('').value, null);
      expect(AccountKey('').value, '');
      expect(AccountKey('ABC').value, 'ABC');
    });

    test('AccountKey toString', () {
      expect(AccountKey('ABC').toString(), '0xABC');
    });

    test('AccountKey identity', () {
      expect(true, AccountKey('ABC') == AccountKey('ABC'));
    });
  });

  test('Account Type', () {
    expect(accountType('user'), AccountType.user);
    expect(accountType('library'), AccountType.library);
    expect(accountType('actor'), AccountType.actor);
    expect(accountType(''), null);
  });

  group('Convex Client', () {
    test('Missing credentials', () async {
      final convexClient = ConvexClient(
        server: convexWorldUri,
        client: http.Client(),
      );

      expect(
        () async => await convexClient.createAccount(),
        throwsException,
      );

      expect(
        () async => await convexClient.accountDetails(),
        throwsException,
      );

      expect(
        () async => await convexClient.prepareTransaction(source: ''),
        throwsException,
      );

      expect(
        () async => await convexClient.submitTransaction(hash: '', sig: ''),
        throwsException,
      );

      expect(
        () async => await convexClient.transact(source: ''),
        throwsException,
      );
    });

    test('Create Account, check details, top up', () async {
      final generatedKeyPair = CryptoSign.randomKeys();

      final generatedAccountKey = AccountKey.fromBin(generatedKeyPair.pk);

      final generatedAddress = await convexClient.createAccount(
        generatedAccountKey,
      );

      expect(generatedAddress != null, true);

      // Update credentials.
      convexClient.setCredentials(
        Credentials(
          address: generatedAddress,
          accountKey: generatedAccountKey,
          secretKey: generatedKeyPair.sk,
        ),
      );

      final account = await convexClient.accountDetails();

      expect(account.type, AccountType.user);
      expect(account.address, generatedAddress);

      final faucetResponse = await convexClient.faucet(amount: 1000000);

      final faucetResponseBody = convert.jsonDecode(faucetResponse.body);

      expect(faucetResponse.statusCode, 200);
      expect(faucetResponseBody.keys.toSet(), {
        'address',
        'amount',
        'value',
      });
    });

    test('Prepare & Submit Transaction', () async {
      final prepareResponse = await convexClient.prepareTransaction(
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

      final submitResponse = await convexClient.submitTransaction(
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
      final result = await convexClient.query(
        source: '(inc 1)',
      );

      expect(result.value, 2);
    });

    test('Self Address', () async {
      final result = await convexClient.query(
        source: '*address*',
      );

      expect(result.value, convexClient.credentials?.address?.value);
    });

    test('Error - UNDECLARED', () async {
      final result = await convexClient.query(
        source: '(incc 1)',
      );

      expect(result.errorCode, 'UNDECLARED');
    });

    test('Error - CAST', () async {
      final result = await convexClient.query(
        source: '(map inc 1)',
      );

      expect(result.errorCode, 'CAST');
    });
  });

  group('Query - Convex Scrypt', () {
    test('Inc', () async {
      var result = await convexClient.query(
        source: 'inc(1)',
        lang: Lang.convexScript,
      );

      expect(result.value, 2);
    });

    test('Self Address', () async {
      final result = await convexClient.query(
        source: '_address_',
        lang: Lang.convexScript,
      );

      expect(result.value, convexClient.credentials?.address?.value);
    });
  });
}
