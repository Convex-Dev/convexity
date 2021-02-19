import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'convex.dart';

class TorusLibrary {
  final _import = '(import torus.exchange :as torus)';

  final ConvexClient convexClient;

  TorusLibrary({@required this.convexClient});

  /// Gets or creates the canonical market for a token.
  Future<Address> createMarket({
    @required Address address,
    @required AccountKey accountKey,
    @required Uint8List secretKey,
    @required Address token,
  }) async {
    final result = await convexClient.transact(
      address: address,
      accountKey: accountKey,
      secretKey: secretKey,
      source: '$_import (torus/create-market $token)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return Address(result.value);
  }

  Future<int> addLiquidity({
    @required Address address,
    @required AccountKey accountKey,
    @required Uint8List secretKey,
    @required Address token,
    @required int tokenAmount,
    @required int cvxAmount,
  }) async {
    final result = await convexClient.transact(
      address: address,
      accountKey: accountKey,
      secretKey: secretKey,
      source: '$_import (torus/add-liquidity $token $tokenAmount $cvxAmount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }
}
