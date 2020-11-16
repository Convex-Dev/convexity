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
