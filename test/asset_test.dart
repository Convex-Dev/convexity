// REQUIREMENTS
// 'libsodium' must be installed on your lachine to be able to run these tests.
// On macOS: brew install libsodium

import 'dart:convert' as convert;

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import '../lib/convex.dart';

Future<Tuple2<Address, KeyPair>> _setupNewAccount(
  ConvexClient convexClient,
) async {
  final generatedKeyPair = CryptoSign.randomKeys();

  final generatedAddress = await convexClient.createAccount(
    accountKey: AccountKey.fromBin(generatedKeyPair.pk),
  );

  final faucetResponse = await convexClient.faucet(
    address: generatedAddress,
    amount: 100000000,
  );

  if (faucetResponse.statusCode != 200) {
    throw Exception('Failed to setup new Account.');
  }

  return Tuple2(generatedAddress, generatedKeyPair);
}

void main() {
  final convexClient = ConvexClient(
    server: convexWorldUri,
    client: http.Client(),
  );

  final fungibleLibrary = FungibleLibrary(
    convexClient: convexClient,
  );

  test('Create a Fungible Token', () async {
    final newAccount = await _setupNewAccount(convexClient);

    final result = await fungibleLibrary.createToken(
      holder: newAccount.item1,
      accountKey: AccountKey.fromBin(newAccount.item2.pk),
      secretKey: newAccount.item2.sk,
      supply: 100,
    );

    expect(result.errorCode, null);
    expect(result.value != null, true);
  });
}
