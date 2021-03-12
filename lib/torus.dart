import 'package:meta/meta.dart';

import 'convex.dart';

class TorusLibrary {
  final _import = '(import torus.exchange :as torus)';

  final ConvexClient convexClient;

  TorusLibrary({@required this.convexClient});

  /// Gets the canonical market for a token. Returns nil if the market does not exist.
  Future<Address> getMarket({@required Address token}) async {
    final result = await convexClient.query(
      source: '$_import (torus/get-market $token)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    if (result.value != null) {
      return Address(result.value);
    }

    return null;
  }

  /// Gets or creates the canonical market for a token.
  Future<Address> createMarket({
    @required Address token,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/create-market $token)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return Address(result.value);
  }

  Future<int> addLiquidity({
    @required Address token,
    @required int tokenAmount,
    @required int cvxAmount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/add-liquidity $token $tokenAmount $cvxAmount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> buy({
    @required Address ofToken,
    @required int amount,
    @required Address withToken,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/buy $ofToken $amount $withToken)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> buyCVX({
    @required Address withToken,
    @required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/buy-cvx $withToken $amount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> buyTokens({
    @required Address ofToken,
    @required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/buy-tokens $ofToken $amount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> sell({
    @required Address ofToken,
    @required int amount,
    @required Address withToken,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/sell $ofToken $amount $withToken)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> sellTokens({
    @required Address ofToken,
    @required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/sell-tokens $ofToken $amount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> sellCVX({
    @required Address withToken,
    @required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/sell-cvx $withToken $amount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<double> price({
    @required Address ofToken,
    Address withToken,
  }) async {
    final result = await convexClient.query(
      source: '$_import (torus/price $ofToken ${withToken ?? ''})',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> buyQuote({
    Address ofToken,
    Address withToken,
    int amount,
  }) async {
    final result = await convexClient.query(
      source: '$_import (torus/buy-quote $ofToken $amount ${withToken ?? ''})',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  /// Query quote for buying CVX with [withToken].
  Future<int> buyCvxQuote({
    Address withToken,
    int amount,
  }) async {
    final result = await convexClient.query(
      source: '$_import'
          '(let [market (or (torus/get-market $withToken) (return nil))]'
          '(call market (buy-cvx-quote $amount))'
          ')',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> sellQuote({
    Address ofToken,
    Address withToken,
    int amount,
  }) async {
    final result = await convexClient.query(
      source: '$_import (torus/sell-quote $ofToken $amount ${withToken ?? ''})',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  /// Query quote for selling CVX with [withToken].
  Future<int> sellCvxQuote({
    Address withToken,
    int amount,
  }) async {
    final result = await convexClient.query(
      source: '$_import'
          '(let [market (or (torus/get-market $withToken) (return nil))]'
          '(call market (sell-cvx-quote $amount))'
          ')',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }
}
