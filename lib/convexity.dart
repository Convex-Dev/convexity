import 'package:meta/meta.dart';

import 'convex.dart' as convex;
import 'model.dart';

Future<List<AssetMetadata>> queryAssets(String convexityAddress) async {
  var source = '(call "$convexityAddress" (all-assets))';

  var result = await convex.query(source: source);

  if (result.errorCode != null) {
    return null;
  }

  var tokens = (result.value as Map<String, dynamic>).entries.map(
    (entry) {
      var address = entry.key;
      var metadata = entry.value as Map<String, dynamic>;

      if (metadata['type'] == 'fungible') {
        return FungibleTokenMetadata(
          address: convex.Address(hex: address),
          name: metadata['name'] as String,
          description: metadata['description'] as String,
          symbol: metadata['symbol'] as String,
          decimals: metadata['decimals'] as int,
        );
      } else if (metadata['type'] == 'non-fungible') {
        return NonFungibleTokenMetadata(
          address: convex.Address(hex: metadata['address'] as String),
          name: metadata['name'] as String,
          description: metadata['description'] as String,
          coll: [],
        );
      }
    },
  ).toList();

  return tokens;
}

class Convexity {
  final Uri convexServerUri;
  final convex.Address actorAddress;

  Convexity({
    @required this.convexServerUri,
    @required this.actorAddress,
  });

  /// Query a particular Asset's metadata.
  Future<AssetMetadata> assetMetadata(convex.Address assetAddress) async {
    var source =
        '(call "${this.actorAddress.hex}" (asset-metadata (address "${assetAddress.hex}")))';

    var result = await convex.query(
      uri: convexServerUri,
      source: source,
    );

    if (result.errorCode != null) {
      return null;
    }

    var m = result.value as Map<String, dynamic>;

    if (m['type'] == 'fungible') {
      return FungibleTokenMetadata(
        address: assetAddress,
        name: m['name'] as String,
        description: m['description'] as String,
        symbol: m['symbol'] as String,
        decimals: 2,
      );
    } else if (m['type'] == 'non-fungible') {
      return NonFungibleTokenMetadata(
        address: assetAddress,
        name: m['name'] as String,
        description: m['description'] as String,
        coll: [],
      );
    }

    return null;
  }

  /// Query all Assets in the registry
  Future<List<AssetMetadata>> allAssets() async {
    var source = '(call "${this.actorAddress.hex}" (all-assets))';

    var result = await convex.query(
      uri: convexServerUri,
      source: source,
    );

    if (result.errorCode != null) {
      return null;
    }

    var tokens = (result.value as Map<String, dynamic>).entries.map(
      (entry) {
        var address = entry.key;
        var metadata = entry.value as Map<String, dynamic>;

        if (metadata['type'] == 'fungible') {
          return FungibleTokenMetadata(
            address: convex.Address(hex: address),
            name: metadata['name'] as String,
            description: metadata['description'] as String,
            symbol: metadata['symbol'] as String,
            decimals: metadata['decimals'] as int,
          );
        } else if (metadata['type'] == 'non-fungible') {
          return NonFungibleTokenMetadata(
            address: convex.Address(hex: metadata['address'] as String),
            name: metadata['name'] as String,
            description: metadata['description'] as String,
            coll: [],
          );
        }
      },
    ).toList();

    return tokens;
  }
}
