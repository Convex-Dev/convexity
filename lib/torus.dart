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
    @required Address ofToken,
    @required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/sell-cvx $ofToken $amount)',
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
      source:
          '$_import (torus/price $ofToken ${withToken != null ? withToken : ''})',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }
}
