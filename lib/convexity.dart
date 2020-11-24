import 'package:meta/meta.dart';

import 'convex.dart' as convex;

import 'model.dart';

class Convexity {
  final Uri convexServerUri;
  final convex.Address actorAddress;

  Convexity({
    @required this.convexServerUri,
    @required this.actorAddress,
  });

  Map<String, dynamic> toMap() => {
        'convexServerUri': convexServerUri,
        'actorAddress': actorAddress,
      };

  /// Query Asset by its Address.
  ///
  /// Returns `null` if there is not metadata, or if there was an error.
  Future<AAsset> aasset(convex.Address aaddresss) async {
    var source =
        '(call "${this.actorAddress.hex}" (asset-metadata (address "${aaddresss.hex}")))';

    var result = await convex.query(
      uri: convexServerUri,
      source: source,
    );

    if (result.errorCode != null) {
      return null;
    }

    if (result.value == null) {
      return null;
    }

    var m = result.value as Map<String, dynamic>;

    if (m['type'] == 'fungible') {
      var metadata = FungibleTokenMetadata(
        name: m['name'] as String,
        description: m['description'] as String,
        symbol: m['symbol'] as String,
        decimals: 2,
      );

      return AAsset(
        type: AssetType.fungible,
        asset: FungibleToken(
          address: aaddresss,
          metadata: metadata,
        ),
      );
    }

    return null;
  }

  /// Query all Assets in the registry.
  Future<Set<AAsset>> aassets() async {
    var source = '(call "${this.actorAddress.hex}" (all-assets))';

    var result = await convex.query(
      uri: convexServerUri,
      source: source,
    );

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
          var asset = FungibleToken(
            address: convex.Address(hex: addressString),
            metadata: FungibleTokenMetadata.fromMap(metadataMap),
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
