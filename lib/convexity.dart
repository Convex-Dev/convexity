import 'convex.dart' as convex;
import 'model.dart';

Future<List<Token>> queryAssets(String convexityAddress) async {
  var source = '(call "$convexityAddress" (assets))';

  var result = await convex.queryResult(source: source);

  if (result.errorCode != null) {
    return null;
  }

  var tokens = (result.value as List).map(
    (m) {
      if (m['type'] == 'fungible') {
        return FungibleToken(
          // TODO
          address: convex.Address(hex: m['symbol'] as String),
          name: m['name'] as String,
          description: m['description'] as String,
          symbol: m['symbol'] as String,
          decimals: m['decimals'] as int,
        );
      } else if (m['type'] == 'non-fungible') {
        return NonFungibleToken(
          address: convex.Address(hex: m['address'] as String),
          name: m['name'] as String,
          description: m['description'] as String,
          coll: [],
        );
      }
    },
  ).toList();

  return tokens;
}

class Convexity {
  final convex.Address address;

  Convexity(this.address);

  /// Query a particular Asset's metadata.
  Future<Token> assetMetadata(convex.Address assetAddress) async {
    var source =
        '(call "${this.address.hex}" (asset-metadata (address "${assetAddress.hex}")))';

    var result = await convex.queryResult(source: source);

    if (result.errorCode != null) {
      return null;
    }

    var m = result.value as Map<String, dynamic>;

    if (m['type'] == 'fungible') {
      return FungibleToken(
        address: assetAddress,
        name: m['name'] as String,
        description: m['description'] as String,
        symbol: m['symbol'] as String,
        decimals: 2,
      );
    } else if (m['type'] == 'non-fungible') {
      return NonFungibleToken(
        address: assetAddress,
        name: m['name'] as String,
        description: m['description'] as String,
        coll: [],
      );
    }

    return null;
  }
}
