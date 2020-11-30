import 'package:meta/meta.dart';

import 'convex.dart' as convex;
import 'model.dart';

class ConvexityClient {
  final convex.ConvexClient convexClient;
  final convex.Address actor;

  ConvexityClient({
    @required this.convexClient,
    @required this.actor,
  });

  /// Query Asset by its Address.
  ///
  /// Returns `null` if there is not metadata, or if there was an error.
  Future<AAsset> aasset(convex.Address aaddress) async {
    var source =
        '(call "${this.actor.hex}" (asset-metadata (address "${aaddress.hex}")))';

    var result = await convexClient.query(source: source);

    if (result.errorCode != null) {
      return null;
    }

    if (result.value == null) {
      return null;
    }

    var m = result.value as Map<String, dynamic>;

    if (m['type'] == 'fungible') {
      var metadata = convex.FungibleTokenMetadata(
        name: m['name'] as String,
        description: m['description'] as String,
        symbol: m['symbol'] as String,
        decimals: 2,
      );

      return AAsset(
        type: AssetType.fungible,
        asset: convex.FungibleToken(
          address: aaddress,
          metadata: metadata,
        ),
      );
    }

    return null;
  }

  /// Query all Assets in the registry.
  Future<Set<AAsset>> aassets() async {
    var source = '(call "${this.actor.hex}" (all-assets))';

    var result = await convexClient.query(source: source);

    if (result.errorCode != null) {
      return null;
    }

    if (result.value == null) {
      return Set.identity();
    }

    var tokens = (result.value as Map<String, dynamic>).entries.map(
      (entry) {
        var addressString = entry.key;
        var metadataMap = entry.value as Map<String, dynamic>;

        if (metadataMap['type'] == 'fungible') {
          var asset = convex.FungibleToken(
            address: convex.Address(hex: addressString),
            metadata: convex.FungibleTokenMetadata.fromJson(metadataMap),
          );

          return AAsset(
            type: AssetType.fungible,
            asset: asset,
          );
        }
      },
    ).toSet();

    return tokens;
  }
}
