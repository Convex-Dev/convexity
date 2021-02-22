import 'package:meta/meta.dart';

import 'convex.dart';

class TorusLibrary {
  final _import = '(import torus.exchange :as torus)';

  final ConvexClient convexClient;

  TorusLibrary({@required this.convexClient});

  /// Gets or creates the canonical market for a token.
  Future<Address> createMarket({
    @required Credentials credentials,
    @required Address token,
  }) async {
    final result = await convexClient.transact(
      address: credentials.address,
      accountKey: credentials.accountKey,
      secretKey: credentials.secretKey,
      source: '$_import (torus/create-market $token)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return Address(result.value);
  }

  Future<int> addLiquidity({
    @required Credentials credentials,
    @required Address token,
    @required int tokenAmount,
    @required int cvxAmount,
  }) async {
    final result = await convexClient.transact(
      address: credentials.address,
      accountKey: credentials.accountKey,
      secretKey: credentials.secretKey,
      source: '$_import (torus/add-liquidity $token $tokenAmount $cvxAmount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> buy({
    @required Credentials credentials,
    @required Address ofToken,
    @required int amount,
    @required Address withToken,
  }) async {
    final result = await convexClient.transact(
      address: credentials.address,
      accountKey: credentials.accountKey,
      secretKey: credentials.secretKey,
      source: '$_import (torus/buy $ofToken $amount $withToken)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int> sell({
    @required Credentials credentials,
    @required Address ofToken,
    @required int amount,
    @required Address withToken,
  }) async {
    final result = await convexClient.transact(
      address: credentials.address,
      accountKey: credentials.accountKey,
      secretKey: credentials.secretKey,
      source: '$_import (torus/sell $ofToken $amount $withToken)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<double> price({
    @required Credentials credentials,
    @required Address ofToken,
    Address withToken,
  }) async {
    final result = await convexClient.transact(
      address: credentials.address,
      accountKey: credentials.accountKey,
      secretKey: credentials.secretKey,
      source:
          '$_import (torus/price $ofToken ${withToken != null ? withToken : ''})',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }
}
