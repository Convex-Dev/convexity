import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'convex.dart';
import 'convexity.dart';
import 'logger.dart';
import 'preferences.dart' as p;
import 'route.dart' as route;

@immutable
class Contact {
  final String name;
  final Address2 address;

  Contact({
    @required this.name,
    @required this.address,
  });

  Contact.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        address = Address2.fromJson(json['address']);

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address.toJson(),
      };

  @override
  bool operator ==(o) => o is Contact && o.address == address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => toJson().toString();
}

@immutable
class Peer {
  final Address address;
  final int stake;
  final int delegatedStake;
  final Uri uri;
  final Map<Address, int> stakes;

  Peer({
    this.address,
    this.stake,
    this.delegatedStake,
    this.uri,
    this.stakes,
  });

  Peer.fromJson(Map<String, dynamic> json)
      : address = Address.fromHex(json['address']),
        stake = json['stake'],
        delegatedStake = json['delegated-stake'],
        uri = Uri.parse(json['uri'] ?? ''),
        stakes = _decodeStakes(json['stakes']);

  Map<String, dynamic> toJson() => {
        'address': address.toJson(),
        'stake': stake,
        'delegated-stake': delegatedStake,
        'uri': uri.toString(),
        'stakes': stakes.toString(),
      };

  static Map<Address, int> _decodeStakes(Map<String, dynamic> json) =>
      json.map((key, value) => MapEntry(Address.fromHex(key), value as int));

  @override
  bool operator ==(o) => o is Peer && o.address == address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => toJson().toString();
}

enum ActivityType {
  transfer,
}

String activityTypeString(ActivityType activityType) {
  switch (activityType) {
    case ActivityType.transfer:
      return 'Transfer';
  }

  return 'Unknown';
}

/// Immutable data class to encode an 'Activity'.
///
/// You can know the concrete type of [payload] using the [type] enum,
/// and then cast to the particular type e.g. `activity.payload as FungibleTransferActivity`.
@immutable
@sealed
class Activity {
  final ActivityType type;
  final dynamic payload;

  Activity({
    @required this.type,
    @required this.payload,
  });

  Activity.fromJson(Map<String, dynamic> json)
      : type = _decodeType(json),
        payload = _decodePayload(json);

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'payload': payload.toJson(),
      };

  static ActivityType _decodeType(Map<String, dynamic> json) {
    if (ActivityType.transfer.toString() == json['type']) {
      return ActivityType.transfer;
    }

    return null;
  }

  static dynamic _decodePayload(Map<String, dynamic> json) {
    if (_decodeType(json) == ActivityType.transfer) {
      return FungibleTransferActivity.fromJson(json['payload']);
    }

    return null;
  }

  @override
  String toString() => toJson().toString();
}

/// Immutable data class to encode a 'Transfer Activity' - a Fungible Token transfer in particular.
@immutable
class FungibleTransferActivity {
  final Address from;
  final Address to;
  final FungibleToken token;
  final int amount;
  final DateTime timestamp;

  FungibleTransferActivity({
    @required this.from,
    @required this.to,
    @required this.token,
    @required this.amount,
    @required this.timestamp,
  });

  FungibleTransferActivity.fromJson(Map<String, dynamic> json)
      : from = Address.fromJson(json['from']),
        to = Address.fromJson(json['to']),
        token = FungibleToken.fromJson(json['token']),
        amount = json['amount'] as int,
        timestamp = DateTime.parse(json['timestamp']);

  Map<String, dynamic> toJson() => {
        'from': from.toJson(),
        'to': to.toJson(),
        'token': token.toJson(),
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
      };
}

enum AssetType {
  fungible,
  nonFungible,
}

/// Returns an (optional) AssetType from string.
AssetType assetType(String s) {
  if (AssetType.fungible.toString() == s) {
    return AssetType.fungible;
  }

  if (AssetType.nonFungible.toString() == s) {
    return AssetType.nonFungible;
  }

  return null;
}

@immutable
class AAsset {
  final AssetType type;
  final dynamic asset;

  AAsset({
    @required this.type,
    @required this.asset,
  });

  @override
  bool operator ==(o) => o is AAsset && o.type == type && o.asset == asset;

  @override
  int get hashCode => asset.hashCode;

  @override
  String toString() => toJson().toString();

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'asset': asset.toJson(),
      };

  static AAsset fromJson(Map<String, dynamic> json) {
    final type = assetType(json['type']);
    final asset = json['asset'];

    return AAsset(
      type: type,
      asset: type == AssetType.fungible
          ? FungibleToken.fromJson(asset)
          : NonFungibleToken.fromJson(asset),
    );
  }
}

enum AddressInputOption {
  textField,
  scan,
}

final convexityAddress = Address.fromHex(
  '0xc797058Ce310cDD0679819715C097D6257Ebf3E2aB531926d8F4D1c2BE87C5ae',
);

/// Immutable Model data class.
///
/// An instance of this class represents a snapshot of the state of the app.
@immutable
class Model {
  final Uri convexServerUri;
  final Address convexityAddress;
  final KeyPair activeKeyPair;
  final List<KeyPair> allKeyPairs;
  final Set<AAsset> following;
  final Set<AAsset> myTokens;
  final List<Activity> activities;
  final Set<Contact> contacts;
  final Set<Address> whitelist;
  final Map<Address2, KeyPair> keyring;
  final Address2 activeAddress2;

  const Model({
    this.convexServerUri,
    this.convexityAddress,
    this.activeKeyPair,
    this.allKeyPairs = const [],
    this.following = const {},
    this.myTokens = const {},
    this.activities = const [],
    this.contacts = const {},
    this.whitelist = const {},
    this.keyring = const {},
    this.activeAddress2,
  });

  Address get activeAddress => activeKeyPair != null
      ? Address.fromHex(Sodium.bin2hex(activeKeyPair.pk))
      : null;

  KeyPair activeKeyPairOrDefault() {
    if (activeKeyPair != null) {
      return activeKeyPair;
    }

    return allKeyPairs.isNotEmpty ? allKeyPairs.last : null;
  }

  KeyPair get activeKeypair2 => keyring[activeAddress2];

  AccountKey get activeAccountKey => AccountKey.fromBin(activeKeypair2.pk);

  Model copyWith({
    Uri convexServerUri,
    Address convexityAddress,
    KeyPair activeKeyPair,
    List<KeyPair> allKeyPairs,
    Set<AAsset> following,
    Set<AAsset> myTokens,
    List<Activity> activities,
    Set<Contact> contacts,
    Set<Address> whitelist,
    Map<Address2, KeyPair> keyring,
    Address2 activeAddress2,
  }) =>
      Model(
        convexServerUri: convexServerUri ?? this.convexServerUri,
        convexityAddress: convexityAddress ?? this.convexityAddress,
        activeKeyPair: activeKeyPair ?? this.activeKeyPair,
        allKeyPairs: allKeyPairs ?? this.allKeyPairs,
        following: following ?? this.following,
        myTokens: myTokens ?? this.myTokens,
        activities: activities ?? this.activities,
        contacts: contacts ?? this.contacts,
        whitelist: whitelist ?? this.whitelist,
        keyring: keyring ?? this.keyring,
        activeAddress2: activeAddress2 ?? this.activeAddress2,
      );

  String toString() => {
        'convexServerUri': convexServerUri.toString(),
        'convexityAddress': convexityAddress.toString(),
        'activeKeyPair': activeKeyPair.toString(),
        'allKeyPairs': allKeyPairs.toString(),
        'following': following.toString(),
        'myTokens': myTokens.toString(),
        'activities': activities.toString(),
        'contacts': contacts.toString(),
        'keyring': keyring.toString(),
        'activeAddress2': activeAddress2.toString(),
      }.toString();
}

void bootstrap({
  @required BuildContext context,
  @required SharedPreferences preferences,
}) {
  try {
    final allKeyPairs = p.readKeyPairs(preferences);
    final activeKeyPair = p.activeKeyPair(preferences);
    final following = p.readFollowing(preferences);
    final myTokens = p.readMyTokens(preferences);
    final activities = p.readActivities(preferences);
    final contacts = p.readContacts(preferences);
    final whitelists = p.readWhitelist(preferences);

    final _model = Model(
      convexServerUri: convexWorldUri,
      convexityAddress: convexityAddress,
      allKeyPairs: allKeyPairs,
      activeKeyPair: activeKeyPair,
      following: following,
      myTokens: myTokens,
      activities: activities,
      contacts: contacts,
      whitelist: whitelists,
    );

    logger.d(_model.toString());

    context.read<AppState>().setState((_) => _model);
  } catch (e, s) {
    logger.e('$e $s');
  }
}

class AppState with ChangeNotifier {
  final client = http.Client();

  Model model;

  AppState({this.model});

  ConvexClient convexClient() => ConvexClient(
        client: client,
        server: model.convexServerUri,
      );

  FungibleLibrary fungibleLibrary() =>
      FungibleLibrary(convexClient: convexClient());

  AssetLibrary assetLibrary() => AssetLibrary(convexClient: convexClient());

  ConvexityClient convexityClient() => model.convexityAddress != null
      ? ConvexityClient(
          convexClient: convexClient(),
          actor: model.convexityAddress,
        )
      : null;

  void setState(Model f(Model m)) {
    model = f(model);

    notifyListeners();
  }

  void setFollowing(Set<AAsset> following, {bool isPersistent = false}) {
    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeFollowing(preferences, following),
      );
    }

    setState((m) => m.copyWith(following: Set<AAsset>.from(following)));
  }

  void follow(AAsset aasset, {bool isPersistent = false}) {
    var following = Set<AAsset>.from(model.following)..add(aasset);

    setFollowing(following, isPersistent: isPersistent);
  }

  void unfollow(AAsset aasset, {bool isPersistent = false}) {
    var following = model.following.where((e) => e != aasset).toSet();

    setFollowing(following, isPersistent: isPersistent);
  }

  /// Set KeyPair `active` as active, and persist it to disk if `isPersistent` is true.
  ///
  /// This method is usually called whenever a new Account is created.
  void setActiveKeyPair(KeyPair active, {bool isPersistent = false}) {
    if (isPersistent) {
      SharedPreferences.getInstance()
          .then((preferences) => p.setActiveKeyPair(preferences, active));
    }

    setState((m) => m.copyWith(activeKeyPair: active));
  }

  void setKeyPairs(List<KeyPair> keyPairs) {
    setState(
      (m) => m.copyWith(allKeyPairs: keyPairs),
    );
  }

  /// Add a new Token to 'My Tokens'.
  void addMyToken(AAsset myToken, {bool isPersistent = false}) {
    var myTokens = Set<AAsset>.from(model.myTokens)..add(myToken);

    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeMyTokens(preferences, myTokens),
      );
    }

    setState(
      (model) => model.copyWith(
        myTokens: myTokens,
      ),
    );
  }

  /// Add a new Activity.
  void addActivity(Activity activity, {bool isPersistent = false}) {
    var activities = List<Activity>.from(model.activities)..add(activity);

    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeActivities(preferences, activities),
      );
    }

    setState(
      (model) => model.copyWith(
        activities: activities,
      ),
    );
  }

  /// Add a new Contact to Address Book.
  void addContact(Contact contact, {bool isPersistent = false}) {
    var contacts = Set<Contact>.from(model.contacts);

    if (contacts.contains(contact)) {
      contacts.remove(contact);
    }

    contacts.add(contact);

    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeContacts(preferences, contacts),
      );
    }

    setState(
      (model) => model.copyWith(
        contacts: contacts,
      ),
    );
  }

  /// Remove Contact from Address Book.
  void removeContact(Contact contact, {bool isPersistent = false}) {
    var contacts = Set<Contact>.from(model.contacts);
    contacts.remove(contact);

    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeContacts(preferences, contacts),
      );
    }

    setState(
      (model) => model.copyWith(
        contacts: contacts,
      ),
    );
  }

  /// Add a new Address to Whitelist.
  void addToWhitelist(Address address, {bool isPersistent = false}) {
    var whitelist = Set<Address>.from(model.whitelist)..add(address);

    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeWhitelist(preferences, whitelist),
      );
    }

    setState((model) => model.copyWith(whitelist: whitelist));
  }

  /// Add a new KeyPair `k`, and persist it to disk if `isPersistent` is true.
  ///
  /// This method is usually called whenever a new Account is created.
  void addKeyPair(KeyPair k, {bool isPersistent = false}) {
    if (isPersistent) {
      SharedPreferences.getInstance()
          .then((preferences) => p.addKeyPair(preferences, k));
    }

    setState(
      (m) => m.copyWith(allKeyPairs: List<KeyPair>.from(m.allKeyPairs)..add(k)),
    );
  }

  /// Remove KeyPair [k].
  void removeKeyPair(KeyPair k, {bool isPersistent = false}) {
    final keyPairs = List<KeyPair>.from(model.allKeyPairs)..remove(k);

    if (isPersistent) {
      SharedPreferences.getInstance()
          .then((preferences) => p.writeKeyPairs(preferences, keyPairs));
    }

    setState(
      (m) {
        return m.copyWith(allKeyPairs: keyPairs);
      },
    );
  }

  /// Reset app state.
  void reset(BuildContext context) {
    SharedPreferences.getInstance().then((preferences) {
      preferences.clear();

      bootstrap(
        context: context,
        preferences: preferences,
      );

      Navigator.popUntil(context, ModalRoute.withName(route.launcher));
    });
  }

  Contact findContact(Address address) => model.contacts.firstWhere(
        (_contact) => _contact.address == address,
        orElse: () => null,
      );

  Contact findContact2(Address2 address) => model.contacts.firstWhere(
        (_contact) => _contact.address == address,
        orElse: () => null,
      );

  bool isAddressMine(Address address) => model.allKeyPairs.any(
        (_keypair) => Address.fromKeyPair(_keypair) == address,
      );

  bool isAddressMine2(Address2 address) => model.keyring.containsKey(address);

  void addToKeyring({
    Address2 address,
    KeyPair keyPair,
    bool isPersistent = false,
  }) {
    if (isPersistent) {}

    setState((m) {
      final _keyring = Map<Address2, KeyPair>.from(m.keyring);
      _keyring[address] = keyPair;

      return m.copyWith(keyring: _keyring);
    });
  }

  void removeAddress(Address2 address, {bool isPersistent = false}) {
    final _keyring = Map<Address2, KeyPair>.from(model.keyring)
      ..remove(address);

    // TODO
    if (isPersistent) {}

    setState(
      (m) {
        return m.copyWith(keyring: _keyring);
      },
    );
  }

  void setActiveAddress2(
    Address2 address, {
    bool isPersistent = false,
  }) {
    if (isPersistent) {}

    setState((m) => m.copyWith(activeAddress2: address));
  }
}
