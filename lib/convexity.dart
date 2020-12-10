import 'dart:typed_data';

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
        '(call 0x${this.actor.hex} (asset-metadata 0x${aaddress.hex}))';

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
        currencySymbol: m['currency-symbol'] as String,
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
    var source = '(call 0x${this.actor.hex} (all-assets))';

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
        var metadata = entry.value as Map<String, dynamic>;

        if (metadata['type'] == 'fungible') {
          var asset = convex.FungibleToken(
            address: convex.Address.fromHex(addressString),
            metadata: convex.FungibleTokenMetadata.fromJson(metadata),
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

  Future<convex.Result> requestToRegister({
    convex.Address holder,
    Uint8List holderSecretKey,
    AAsset aasset,
  }) {
    var fungible = aasset.asset as convex.FungibleToken;

    var metadataStr = '{'
        ':name "${fungible.metadata.name}",'
        ':description "${fungible.metadata.description}",'
        ':type :fungible,'
        ':symbol "${fungible.metadata.symbol}",'
        ':currency-symbol "${fungible.metadata.currencySymbol}",'
        ':decimals ${fungible.metadata.decimals}'
        '}';

    var source =
        '(call 0x${this.actor.hex} (request-registry 0x${fungible.address.hex} $metadataStr))';

    return convexClient.transact(
      caller: holder,
      secretKey: holderSecretKey,
      source: source,
    );
  }
}
