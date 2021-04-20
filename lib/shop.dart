import 'package:convex_wallet/convex.dart';
import 'package:tuple/tuple.dart';

const SHOP_ADDRESS = Address(52);

class Listing {
  int id;
  Tuple2<double, Address?> price;
  Tuple2<Address, int> asset;
  Address owner;

  // Add string description.

  Listing({
    required this.id,
    required this.price,
    required this.asset,
    required this.owner,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'price': [price.item1, price.item2?.toJson()],
        'asset': [asset.item1.toJson(), asset.item2],
        'owner': owner.toJson(),
      };

  String toString() => toJson().toString();
}

/// Returns available Listings.
Future<List<Listing>> listings(ConvexClient convexClient) async {
  Result result = await convexClient.query(
    source: '(call $SHOP_ADDRESS (shop))',
  );

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

/// Returns a Listing for Asset, or null if there isn't one.
Future<Listing?> listing(
  ConvexClient convexClient,
  Tuple2<Address, int> asset,
) async {
  List<Listing> l = await listings(convexClient);

  return l.firstWhere((listing) => listing.asset == asset, orElse: null);
}

Future<int> addListing(
  ConvexClient convexClient, {
  required Tuple2<Address, int> asset,
  required Tuple2<double, Address?> price,
}) async {
  final l = '{'
      ' :asset [${asset.item1} ${asset.item2}]'
      ' :price [${price.item1} ${price.item2 ?? ''}]'
      '}';

  Result result = await convexClient.transact(
    source: '(call $SHOP_ADDRESS (add-listing $l))',
  );

  if (result.errorCode != null)
    throw Exception(
      'Failed to add listing. Error: ${result.errorCode} - ${result.value}.',
    );

  return result.value;
}

Future<bool> removeListing(
  ConvexClient convexClient, {
  required int id,
}) async {
  Result result = await convexClient.transact(
    source: '(call $SHOP_ADDRESS (remove-listing $id))',
  );

  if (result.errorCode != null)
    throw Exception(
      'Failed to remove listing. Error: ${result.errorCode} - ${result.value}.',
    );

  return true;
}
