// REQUIREMENTS
// 'libsodium' must be installed on your lachine to be able to run these tests.
// On macOS: brew install libsodium

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import '../lib/convex.dart';
import '../lib/model.dart';
import '../lib/convexity.dart';
import '../lib/logger.dart';

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

  final convexityClient = ConvexityClient(
    convexClient: convexClient,
    actor: convexityAddress,
  );

  test('Create a Market', () async {
    final newAccount = await _setupNewAccount(convexClient);
    final newAccountAddress = newAccount.item1;
    final newAccountKeyPair = newAccount.item2;

    final result = await fungibleLibrary.createToken(
      holder: newAccountAddress,
      accountKey: AccountKey.fromBin(newAccountKeyPair.pk),
      secretKey: newAccountKeyPair.sk,
      supply: 1000,
    );

    expect(result.errorCode, null);
    expect(result.value != null, true);

    final metadata = FungibleTokenMetadata(
      name: 'Sample Token ${DateTime.now()}',
      description: 'Description of Sample Token ${DateTime.now()}.',
      symbol: 'ST',
      currencySymbol: 'ST\$',
      decimals: 2,
    );

    final fungible = FungibleToken(
      address: Address(result.value),
      metadata: metadata,
    );

    final aasset = AAsset(
      type: AssetType.fungible,
      asset: fungible,
    );

    final result2 = await convexityClient.requestToRegister(
      holder: newAccountAddress,
      holderAccountKey: AccountKey.fromBin(newAccountKeyPair.pk),
      holderSecretKey: newAccountKeyPair.sk,
      aasset: aasset,
    );

    expect(result2.errorCode, null);
    expect(result2.value != null, true);

    final market = await convexClient.transact(
      address: newAccountAddress,
      accountKey: AccountKey.fromBin(newAccountKeyPair.pk),
      secretKey: newAccountKeyPair.sk,
      source:
          '(import torus.exchange :as torus) (torus/create-market ${fungible.address})',
    );

    logger.d(market.toJson());

    expect(market.errorCode, null);

    final liquidity = await convexClient.transact(
      address: newAccountAddress,
      accountKey: AccountKey.fromBin(newAccountKeyPair.pk),
      secretKey: newAccountKeyPair.sk,
      source: '(torus/add-liquidity ${fungible.address} 1000 1000000)',
    );

    logger.d(liquidity.toJson());

    expect(liquidity.errorCode, null);
  });
}
