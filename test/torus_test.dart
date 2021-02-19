import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

import '../lib/logger.dart';
import '../lib/convex.dart';
import '../lib/torus.dart';

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

  final torus = TorusLibrary(convexClient: convexClient);

  test('Create a Market', () async {
    final newAccount = await _setupNewAccount(convexClient);
    final newAccountAddress = newAccount.item1;
    final newAccountKeyPair = newAccount.item2;

    final credentials = Credentials(
      address: newAccountAddress,
      accountKey: AccountKey.fromBin(newAccountKeyPair.pk),
      secretKey: newAccountKeyPair.sk,
    );

    final token1 = await fungibleLibrary.createToken2(
      credentials: credentials,
      supply: 1000,
    );

    final token2 = await fungibleLibrary.createToken2(
      credentials: credentials,
      supply: 1000000,
    );

    final market1 = await torus.createMarket(
      credentials: credentials,
      token: token1,
    );

    final market2 = await torus.createMarket(
      credentials: credentials,
      token: token2,
    );

    logger.d('Market1 $market1');
    logger.d('Market2 $market2');

    final liquidity1 = await torus.addLiquidity(
      credentials: credentials,
      token: token1,
      tokenAmount: 1000,
      cvxAmount: 10000000,
    );

    final liquidity2 = await torus.addLiquidity(
      credentials: credentials,
      token: token2,
      tokenAmount: 1000000,
      cvxAmount: 5000000,
    );

    logger.d('Liquidity1 $liquidity1');
    logger.d('Liquidity2 $liquidity2');

    final bought = await torus.buy(
      credentials: credentials,
      ofToken: token1,
      amount: 100,
      withToken: token2,
    );

    logger.d('Bought $bought');
  });
}
