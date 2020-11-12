import 'convex.dart' as convex;
import 'model.dart';

Future<List<Token>> queryAssets(String convexityAddress) async {
  var source = '(call "$convexityAddress" (A-meta))';

  var result = await convex.queryResult(source: source);

  if (result.errorCode != null) {
    return null;
  }

  var tokens = (result.value as List).map(
    (m) {
      return FungibleToken(
        name: m['name'] as String,
        balance: m['balance'] as int,
      );
    },
  ).toList();

  return tokens;
}
