import 'package:convex_wallet/convex.dart';
import 'package:tuple/tuple.dart';

const SHOP_ADDRESS = Address(62);

class Listing {
  int id;
  Tuple2<double, Address?> price;
  Tuple2<Address, int> asset;
  Address owner;

  Listing({
    required this.id,
    required this.price,
    required this.asset,
    required this.owner,
  });
}

Future<List<Listing>> listings(ConvexClient client) async {
  Result result = await client.query(source: '(call $SHOP_ADDRESS (shop))');

  if (result.errorCode != null)
    throw Exception(
      'Failed to query listings. Error: ${result.errorCode} - ${result.value}.',
    );

  final Iterable l = result.value as Iterable;

  final List<Listing> listings = l.map((m) {
    List p = m['price'];

    final price = Tuple2<double, Address?>(
      (p.first as num).toDouble(),
      p.length == 2 ? Address(p.last) : null,
    );

    List a = m['asset'];

    final asset = Tuple2<Address, int>(
      Address(a.first),
      a.last,
    );

    return Listing(
      id: m['id'],
      price: price,
      asset: asset,
      owner: Address(m['owner']),
    );
  }).toList();

  return listings;
}
