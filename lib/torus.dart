import 'package:tuple/tuple.dart';

import 'convex.dart';

class TorusLibrary {
  final _import = '(import torus.exchange :as torus)';

  final ConvexClient convexClient;

  TorusLibrary({required this.convexClient});

  /// Gets the canonical market for a token. Returns nil if the market does not exist.
  Future<Address?> getMarket({required Address token}) async {
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
    required Address token,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/create-market $token)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return Address(result.value);
  }

  Future<int?> addLiquidity({
    required Address token,
    required int tokenAmount,
    required int cvxAmount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/add-liquidity $token $tokenAmount $cvxAmount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int?> buy({
    required Address ofToken,
    required int amount,
    required Address withToken,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/buy $ofToken $amount $withToken)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int?> buyCVX({
    required Address withToken,
    required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/buy-cvx $withToken $amount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int?> buyTokens({
    required Address ofToken,
    required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/buy-tokens $ofToken $amount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int?> sell({
    required Address ofToken,
    required int amount,
    required Address? withToken,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/sell $ofToken $amount $withToken)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int?> sellTokens({
    required Address ofToken,
    required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/sell-tokens $ofToken $amount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<int?> sellCVX({
    required Address withToken,
    required int amount,
  }) async {
    final result = await convexClient.transact(
      source: '$_import (torus/sell-cvx $withToken $amount)',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  Future<double?> price({
    Address? ofToken,
    Address? withToken,
  }) async {
    assert(
      !(ofToken == null && withToken == null),
      'OfToken and withToken are null; at least one must be not null.',
    );

    final result = ofToken == null
        ? await convexClient.query(
            source: '$_import (torus/price $withToken)',
          )
        : await convexClient.query(
            source: '$_import (torus/price $ofToken ${withToken ?? ''})',
          );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return ofToken == null ? 1 / result.value : result.value;
  }

  Future<int?> buyQuote({
    Address? ofToken,
    Address? withToken,
    int? amount,
  }) async {
    final result = await convexClient.query(
      source: '$_import (torus/buy-quote $ofToken $amount ${withToken ?? ''})',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  /// Query quote for buying CVX with [withToken].
  Future<int?> buyCvxQuote({
    Address? withToken,
    int? amount,
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

  Future<int?> sellQuote({
    Address? ofToken,
    Address? withToken,
    int? amount,
  }) async {
    final result = await convexClient.query(
      source: '$_import (torus/sell-quote $ofToken $amount ${withToken ?? ''})',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return result.value;
  }

  /// Query quote for selling CVX with [withToken].
  Future<int?> sellCvxQuote({
    Address? withToken,
    int? amount,
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

  /// Liquidity pool of **of Token** and **with Token**.
  ///
  /// If a Token is `null`, it's considered to be CVX.
  ///
  /// The liquidity pool of CVX is the balance of the Market (Actor).
  ///
  /// Returns `Tuple2<int, int>` with 'of liquidity pool' and 'with liquidity pool' respectively.
  Future<Tuple2<int?, int?>> liquidity({
    Address? ofToken,
    Address? withToken,
  }) async {
    final ofMarket = ofToken != null ? await getMarket(token: ofToken) : null;

    final withMarket =
        withToken != null ? await getMarket(token: withToken) : null;

    // -- Buying/selling CVX
    // 'of' is null, therefore, we are buying/selling CVX.
    if (ofToken == null) {
      final withBalance = withMarket != null
          ? await convexClient.query(
              source: '(import convex.asset :as asset)'
                  '(asset/balance $withToken $withMarket)',
            )
          : null;

      // 'with Market' must exist when we're buying/selling CVX.
      // If there isn't a Market, 'of balance' will be null.
      final ofBalance =
          withMarket != null ? await convexClient.balance(withMarket) : null;

      return Tuple2<int?, int?>(ofBalance, withBalance?.value);
    }

    // -- Buying/selling Tokens
    // 'of' is not null, therefore, we are buying/selling Tokens.

    final ofBalance = ofMarket != null
        ? await convexClient.query(
            source: '(import convex.asset :as asset)'
                '(asset/balance $ofToken $ofMarket)',
          )
        : null;

    final isMissingWithMarket = withToken != null && withMarket == null;

    // When trading with Token, we need to query the balance of the 'of Market' too.
    // It's possible to have a 'with' Token but not have a Market for it.
    // Short circuits to null if there's a 'with' Token but doesn't have a Market for it.
    //
    // If there isn't a 'with' Token, we're exchanging for CVX, therefore,
    // we must query the balance of the 'of' Market instead.

    final withBalance = isMissingWithMarket
        ? null
        : withMarket != null
            ? await convexClient.query(
                source: '(import convex.asset :as asset)'
                    '(asset/balance $withToken $withMarket)',
              )
            : await convexClient.balance(ofMarket);

    return Tuple2<int?, int?>(
      ofBalance?.value,
      withBalance is Result ? withBalance.value : withBalance as int?,
    );
  }
}
