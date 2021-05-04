import 'convex.dart' as convex;
import 'model.dart';
import 'config.dart' as config;
import 'logger.dart';

class ConvexityClient {
  final convex.ConvexClient convexClient;
  final convex.Address? actor;

  final Map<convex.Address, AAsset> _cache = {};

  ConvexityClient({
    required this.convexClient,
    required this.actor,
  });

  /// Query Asset by its Address.
  ///
  /// Returns `null` if there is not metadata, or if there was an error.
  Future<AAsset?> asset(convex.Address addr) async {
    final aasset = _cache[addr];

    if (aasset != null) {
      return aasset;
    }

    var source = '(call ${this.actor} (asset-metadata $addr))';

    if (config.isDebug()) {
      logger.d(source);
    }

    var result = await convexClient.query(source: source);

    if (config.isDebug()) {
      logger.d(result);
    }

    if (result.errorCode != null) {
      return null;
    }

    if (result.value == null) {
      return null;
    }

    var metadata = result.value as Map<String, dynamic>;

    if (metadata['type'] == 'fungible') {
      final aasset = AAsset(
        type: AssetType.fungible,
        asset: convex.FungibleToken(
          address: addr,
          metadata: convex.FungibleTokenMetadata.fromJson(metadata),
        ),
      );

      _cache[addr] = aasset;

      return aasset;
    }

    return null;
  }

  /// Query all Assets in the registry.
  Future<Set<AAsset>?> assets() async {
    var source = '(call ${this.actor} (all-assets))';

    var result = await convexClient.query(source: source);

    if (result.errorCode != null) {
      return null;
    }

    if (result.value == null) {
      return Set.identity();
    }

    var tokens = (result.value as Map<String, dynamic>).entries.map(
      (entry) {
        final address = convex.Address.fromStr(entry.key);
        final metadata = entry.value as Map<String, dynamic>;
        final tokenType = metadata['type'] == 'fungible'
            ? AssetType.fungible
            : AssetType.nonFungible;

        switch (tokenType) {
          case AssetType.fungible:
            var asset = convex.FungibleToken(
              address: address,
              metadata: convex.FungibleTokenMetadata.fromJson(metadata),
            );

            return AAsset(
              type: AssetType.fungible,
              asset: asset,
            );
          case AssetType.nonFungible:
            var asset = convex.NonFungibleToken(
              address: address,
              metadata: convex.NonFungibleTokenMetadata.fromJson(metadata),
            );

            return AAsset(
              type: AssetType.nonFungible,
              asset: asset,
            );
        }
      },
    ).toSet();

    return tokens;
  }

  Future<convex.Result> requestToRegister({
    required AAsset aasset,
  }) {
    var fungible = aasset.asset as convex.FungibleToken;

    var metadataStr = '{'
        ':name "${fungible.metadata.name}",'
        ':description "${fungible.metadata.description}",'
        ':image ${fungible.metadata.image == null ? 'nil' : '"${fungible.metadata.image}"'},'
        ':type :fungible,'
        ':symbol "${fungible.metadata.tickerSymbol}",'
        ':currency-symbol "${fungible.metadata.currencySymbol}",'
        ':decimals ${fungible.metadata.decimals}'
        '}';

    var source =
        '(call ${this.actor!.value} (request-registry ${fungible.address} $metadataStr))';

    return convexClient.transact(source: source);
  }
}
