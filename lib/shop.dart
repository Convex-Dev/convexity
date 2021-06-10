import 'package:convex_wallet/convex.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

import 'currency.dart' as currency;

const SHOP_ADDRESS = Address(183);

const PRICE_PRECISION = 5;

@immutable
class NewListing {
  final String description;
  final Tuple2<int, Address?> price;
  final Tuple2<Address, int> asset;
  final String? image;

  const NewListing({
    required this.description,
    required this.price,
    required this.asset,
    this.image,
  });
}

@immutable
class Listing {
  final int id;
  final String description;
  final String? image;
  final Tuple2<int, Address?> price;
  final Tuple2<Address, int> asset;
  final Address owner;

  const Listing({
    required this.id,
    required this.description,
    required this.price,
    required this.asset,
    required this.owner,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'image': image,
        'price': [price.item1, price.item2?.toJson()],
        'asset': [asset.item1.toJson(), asset.item2],
        'owner': owner.toJson(),
      };

  String toString() => toJson().toString();

  static Listing fromJson(Map<String, dynamic> json) {
    List p = json['price'];

    final price = Tuple2<int, Address?>(
      p.first,
      p.last != null ? Address(p.last) : null,
    );

    List a = json['asset'];

    final asset = Tuple2<Address, int>(
      Address(a.first),
      a.last,
    );

    return Listing(
      id: json['id'],
      description: json['description'] ?? 'No description',
      image: json['image'],
      price: price,
      asset: asset,
      owner: Address(json['owner']),
    );
  }
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

  final List<Listing> listings =
      l.map((json) => Listing.fromJson(json)).toList();

  return listings;
}

/// Returns a Listing for Asset, or null if there isn't one.
Future<Listing?> listing(
  ConvexClient convexClient,
  Tuple2<Address, int> asset,
) async {
  List<Listing> l = await listings(convexClient);

  try {
    return l.firstWhere((listing) => listing.asset == asset);
  } catch (e) {
    return null;
  }
}

Future<int> addListing({
  required ConvexClient convexClient,
  required NewListing newListing,
}) async {
  final l = '{'
      ' :description "${newListing.description}"'
      ' :asset [${newListing.asset.item1} ${newListing.asset.item2}]'
      ' :price [${newListing.price.item1} ${newListing.price.item2 ?? 'nil'}]'
      ' ${newListing.image != null ? ':image "${newListing.image}"' : ''}'
      '}';

  Result result = await convexClient.transact(
    source: '(import convex.asset :as asset)'
        '(asset/offer $SHOP_ADDRESS [${newListing.asset.item1} ${newListing.asset.item2}])'
        '(call $SHOP_ADDRESS (add-listing $l))',
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

Future<bool> buyListing(
  ConvexClient convexClient, {
  required Listing listing,
}) async {
  Result result = await convexClient.transact(
    source: listing.price.item2 == null
        ? '(call $SHOP_ADDRESS ${listing.price.item1} (buy-listing ${listing.id}))'
        : '(do'
            '(import convex.asset :as asset)'
            '(asset/offer $SHOP_ADDRESS [${listing.price.item2} ${listing.price.item1}])'
            '(call $SHOP_ADDRESS (buy-listing ${listing.id}))'
            ')',
  );

  if (result.errorCode != null)
    throw Exception(
      'Failed to buy listing. Error: ${result.errorCode} - ${result.value}.',
    );

  return true;
}

Future<List<Listing>> myListings({
  required ConvexClient convexClient,
  required Address myAddress,
}) async {
  final available = await listings(convexClient);

  return available.where((listing) => listing.owner == myAddress).toList();
}

String priceStr(Tuple2<int, Address?> price) => price.item2 == null
    ? currency
        .copperTo(
          price.item1.toInt(),
          toUnit: currency.CvxUnit.gold,
        )
        .toStringAsPrecision(PRICE_PRECISION)
    : price.item1.toStringAsPrecision(PRICE_PRECISION);
