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
    AccountKey.fromBin(generatedKeyPair.pk),
  );

  final faucetResponse = await convexClient.faucet(
    address: generatedAddress,
    amount: 100000000,
  );

  if (faucetResponse.statusCode != 200) {
    throw Exception('Failed to setup new Account.');
  }

  return Tuple2(generatedAddress!, generatedKeyPair);
}

void main() {
  var convexClient = ConvexClient(
    server: convexWorldUri,
    client: http.Client(),
  );

  test('Market - Buy & sell', () async {
    final newAccount = await _setupNewAccount(convexClient);
    final newAccountAddress = newAccount.item1;
    final newAccountKeyPair = newAccount.item2;

    // // Update credentials.
    convexClient.setCredentials(
      Credentials(
        address: newAccountAddress,
        accountKey: AccountKey.fromBin(newAccountKeyPair.pk),
        secretKey: newAccountKeyPair.sk,
      ),
    );

    final fungibleLibrary = FungibleLibrary(
      convexClient: convexClient,
    );

    final assetLibrary = AssetLibrary(
      convexClient: convexClient,
    );

    final torus = TorusLibrary(convexClient: convexClient);

    final token1 = await fungibleLibrary.createToken2(
      supply: 1000000,
    );

    logger.d('Token1 $token1');

    final token2 = await fungibleLibrary.createToken2(
      supply: 1000000,
    );

    logger.d('Token2 $token2');

    final market1 = await torus.createMarket(
      token: token1,
    );

    logger.d('Market1 $market1 (Token $token1)');

    final market2 = await torus.createMarket(
      token: token2,
    );

    logger.d('Market2 $market2 (Token $token2)');

    final liquidity1 = await torus.addLiquidity(
      token: token1,
      tokenAmount: 80000,
      cvxAmount: 5000000,
    );

    logger.d('Liquidity1 (Token1 $token1): $liquidity1');

    final liquidity2 = await torus.addLiquidity(
      token: token2,
      tokenAmount: 80000,
      cvxAmount: 5000000,
    );

    logger.d('Liquidity2 (Token2 $token2): $liquidity2');

    final price1 = await torus.price(
      ofToken: token1,
    );

    logger.d('Token1 $token1 price: $price1');

    final price2 = await torus.price(
      ofToken: token1,
      withToken: token2,
    );

    logger.d('Token2 $token1 with $token2 price: $price2');

    final pricePaid = await torus.buy(
      ofToken: token1,
      amount: 1,
      withToken: token2,
    );

    logger.d('Price paid for Token1 $token1: $pricePaid');

    final token1Balance = await assetLibrary.balance(
      asset: token1,
      owner: newAccountAddress,
    );

    logger.d('Token1 $token1 balance: $token1Balance');

    final sellToken1Price = await torus.sell(
      ofToken: token1,
      amount: 100,
      withToken: token2,
    );

    logger.d('Token1 $token1 sell price: $sellToken1Price');

    final sellToken2Price = await torus.sell(
      ofToken: token2,
      amount: 50,
      withToken: token1,
    );

    logger.d('Token2 $token2 sell price: $sellToken2Price');
  });
}
