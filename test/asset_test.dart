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

  final fungibleLibrary = FungibleLibrary(
    convexClient: convexClient,
  );

  test('Create a Fungible Token', () async {
    final generatedKeyPair = CryptoSign.randomKeys();

    final generatedAddress = await convexClient.createAccount(
      accountKey: AccountKey.fromBin(generatedKeyPair.pk),
    );

    final faucetResponse = await convexClient.faucet(
      address: generatedAddress,
      amount: 100000000,
    );

    expect(faucetResponse.statusCode, 200);

    final result = await fungibleLibrary.createToken(
      holder: generatedAddress,
      accountKey: AccountKey.fromBin(generatedKeyPair.pk),
      secretKey: generatedKeyPair.sk,
      supply: 100,
    );

    expect(result.errorCode, null);
    expect(result.value != null, true);
  });
}
