import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'torus.dart';
import 'convex.dart';
import 'convexity.dart';
import 'logger.dart';
import 'preferences.dart' as p;
import 'route.dart' as route;
import 'format.dart' as format;
import 'currency.dart' as currency;

// ignore: non_constant_identifier_names
final CVX = FungibleToken(
  address: Address(-1),
  metadata: FungibleTokenMetadata(
    name: 'Convex Gold',
    description: 'Convex Gold Coin.',
    tickerSymbol: 'CVX',
    currencySymbol: '',
    decimals: currency.cvxUnitDecimals(currency.CvxUnit.gold),
  ),
);

bool isDefaultFungibleToken(FungibleToken token) {
  final defaultTokens = {
    34,
    28,
    40,
    42,
    30,
    32,
    44,
    38,
    36,
  };

  return defaultTokens.contains(token.address.value);
}

enum ExchangeAction {
  buy,
  sell,
}

@immutable
class ExchangeParams {
  final ExchangeAction? action;
  final FungibleToken? ofToken;
  final String? amount;
  final FungibleToken? withToken;

  ExchangeParams({
    this.action,
    this.ofToken,
    this.amount,
    this.withToken,
  });

  int get amountInt => ofToken == null
      ? currency.toCopper(
          currency.decimal(amount!),
          fromUnit: currency.CvxUnit.gold,
        )
      : format.readFungibleCurrency(metadata: ofToken!.metadata, s: amount!);

  bool get isAmountValid {
    try {
      if (amount == null || amount!.isEmpty) {
        return false;
      }

      int.parse(amount!);

      return true;
    } catch (e) {
      return false;
    }
  }

  ExchangeParams swap() => ExchangeParams(
        action: this.action,
        amount: this.amount,
        ofToken: this.withToken,
        withToken: this.ofToken,
      );

  ExchangeParams setOfToken(FungibleToken? ofToken) => ExchangeParams(
        action: this.action,
        ofToken: ofToken,
        amount: this.amount,
        withToken: this.withToken,
      );

  ExchangeParams setWithToken(FungibleToken? withToken) => ExchangeParams(
        action: this.action,
        ofToken: this.ofToken,
        amount: this.amount,
        withToken: withToken,
      );

  ExchangeParams resetWith() => ExchangeParams(
        action: this.action,
        ofToken: this.ofToken,
        amount: '',
        withToken: null,
      );

  ExchangeParams emptyAmount() => ExchangeParams(
        action: this.action,
        ofToken: this.ofToken,
        amount: '',
        withToken: this.withToken,
      );

  ExchangeParams copyWith({
    ExchangeAction? action,
    FungibleToken? ofToken,
    String? amount,
    FungibleToken? withToken,
  }) =>
      ExchangeParams(
        action: action ?? this.action,
        ofToken: ofToken ?? this.ofToken,
        amount: amount ?? this.amount,
        withToken: withToken ?? this.withToken,
      );

  ExchangeParams copyWith2({
    ExchangeAction Function()? action,
    FungibleToken Function()? ofToken,
    String Function()? amount,
    FungibleToken? Function()? withToken,
  }) =>
      ExchangeParams(
        action: action != null ? action() : this.action,
        ofToken: ofToken != null ? ofToken() : this.ofToken,
        amount: amount != null ? amount() : this.amount,
        withToken: withToken != null ? withToken() : this.withToken,
      );

  Map<String, dynamic> toJson() => {
        'action': action?.toString(),
        'ofToken': ofToken?.toJson(),
        'withToken': withToken?.toJson(),
        'amount': amount,
      };
}

@immutable
class Contact {
  final String name;
  final Address address;

  Contact({
    required this.name,
    required this.address,
  });

  Contact.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        address = Address.fromJson(json['address']);

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
  final String? address;
  final int? stake;
  final int? delegatedStake;
  final Uri? uri;
  final Map<Address, int>? stakes;

  Peer({
    this.address,
    this.stake,
    this.delegatedStake,
    this.uri,
    this.stakes,
  });

  Peer.fromJson(Map<String, dynamic> json)
      : address = json['address'],
        stake = json['stake'],
        delegatedStake = json['delegated-stake'],
        uri = Uri.parse(json['uri'] ?? ''),
        stakes = _decodeStakes(json['stakes']);

  Map<String, dynamic> toJson() => {
        'address': address,
        'stake': stake,
        'delegated-stake': delegatedStake,
        'uri': uri.toString(),
        'stakes': stakes.toString(),
      };

  static Map<Address, int> _decodeStakes(Map<String, dynamic> json) =>
      json.map((key, value) => MapEntry(Address.fromStr(key), value as int));

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

String activityTypeString(ActivityType? activityType) {
  switch (activityType) {
    case ActivityType.transfer:
      return 'Transfer';
    default:
      return 'Unknown';
  }
}

/// Immutable data class to encode an 'Activity'.
///
/// You can know the concrete type of [payload] using the [type] enum,
/// and then cast to the particular type e.g. `activity.payload as FungibleTransferActivity`.
@immutable
@sealed
class Activity {
  final ActivityType? type;
  final dynamic payload;

  Activity({
    required this.type,
    required this.payload,
  });

  Activity.fromJson(Map<String, dynamic> json)
      : type = _decodeType(json),
        payload = _decodePayload(json);

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'payload': payload.toJson(),
      };

  static ActivityType? _decodeType(Map<String, dynamic> json) {
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
  final Address? from;
  final Address? to;
  final FungibleToken? token;
  final int? amount;
  final DateTime timestamp;

  FungibleTransferActivity({
    required this.from,
    required this.to,
    required this.token,
    required this.amount,
    required this.timestamp,
  });

  FungibleTransferActivity.fromJson(Map<String, dynamic> json)
      : from = Address.fromJson(json['from']),
        to = Address.fromJson(json['to']),
        token = FungibleToken.fromJson(json['token']),
        amount = json['amount'] as int?,
        timestamp = DateTime.parse(json['timestamp']);

  Map<String, dynamic> toJson() => {
        'from': from!.toJson(),
        'to': to!.toJson(),
        'token': token!.toJson(),
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
      };
}

enum AssetType {
  fungible,
  nonFungible,
}

/// Returns an (optional) AssetType from string.
AssetType? assetType(String? s) {
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
  final AssetType? type;
  final dynamic asset;

  AAsset({
    required this.type,
    required this.asset,
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

final convexityAddress = Address(3365);

/// Immutable Model data class.
///
/// An instance of this class represents a snapshot of the state of the app.
@immutable
class Model {
  final Uri convexServerUri;
  final Address convexityAddress;
  final Set<AAsset> following;
  final Set<AAsset> myTokens;
  final List<Activity> activities;
  final Set<Contact> contacts;
  final Map<Address, KeyPair> keyring;
  final Address? activeAddress;
  final FungibleToken? defaultWithToken;

  const Model({
    required this.convexServerUri,
    required this.convexityAddress,
    this.following = const {},
    this.myTokens = const {},
    this.activities = const [],
    this.contacts = const {},
    this.keyring = const {},
    this.activeAddress,
    this.defaultWithToken,
  });

  KeyPair? get activeKeyPair => keyring[activeAddress];

  AccountKey? get activeAccountKey =>
      activeKeyPair?.pk != null ? AccountKey.fromBin(activeKeyPair!.pk) : null;

  Model copyWith({
    Uri? convexServerUri,
    Address? convexityAddress,
    KeyPair? activeKeyPair,
    Set<AAsset>? following,
    Set<AAsset>? myTokens,
    List<Activity>? activities,
    Set<Contact>? contacts,
    Map<Address, KeyPair>? keyring,
    Address? activeAddress,
    FungibleToken? defaultWithToken,
  }) =>
      Model(
        convexServerUri: convexServerUri ?? this.convexServerUri,
        convexityAddress: convexityAddress ?? this.convexityAddress,
        following: following ?? this.following,
        myTokens: myTokens ?? this.myTokens,
        activities: activities ?? this.activities,
        contacts: contacts ?? this.contacts,
        keyring: keyring ?? this.keyring,
        activeAddress: activeAddress ?? this.activeAddress,
        defaultWithToken: defaultWithToken ?? this.defaultWithToken,
      );

  Model copyWith2({
    Uri Function()? convexServerUri,
    Address Function()? convexityAddress,
    KeyPair Function()? activeKeyPair,
    Set<AAsset> Function()? following,
    Set<AAsset> Function()? myTokens,
    List<Activity> Function()? activities,
    Set<Contact> Function()? contacts,
    Map<Address, KeyPair> Function()? keyring,
    Address Function()? activeAddress,
    FungibleToken? Function()? defaultWithToken,
  }) =>
      Model(
        convexServerUri:
            convexServerUri != null ? convexServerUri() : this.convexServerUri,
        convexityAddress: convexityAddress != null
            ? convexityAddress()
            : this.convexityAddress,
        following: following != null ? following() : this.following,
        myTokens: myTokens != null ? myTokens() : this.myTokens,
        activities: activities != null ? activities() : this.activities,
        contacts: contacts != null ? contacts() : this.contacts,
        keyring: keyring != null ? keyring() : this.keyring,
        activeAddress: activeAddress != null
            ? activeAddress as Address?
            : this.activeAddress,
        defaultWithToken: defaultWithToken != null
            ? defaultWithToken()
            : this.defaultWithToken,
      );

  String toString() => {
        'convexServerUri': convexServerUri.toString(),
        'convexityAddress': convexityAddress.toString(),
        'following': following.toString(),
        'myTokens': myTokens.toString(),
        'activities': activities.toString(),
        'contacts': contacts.toString(),
        'keyring': keyring.toString(),
        'activeAddress': activeAddress?.toString(),
        'defaultWithToken': defaultWithToken?.toString(),
      }.toString();
}

void bootstrap({
  required BuildContext context,
  required SharedPreferences preferences,
}) {
  try {
    final keyring = p.readKeyring(preferences);
    final activeAddress = p.readActiveAddress(preferences);
    final following = p.readFollowing(preferences);
    final myTokens = p.readMyTokens(preferences);
    final activities = p.readActivities(preferences);
    final contacts = p.readContacts(preferences);
    final defaultWithToken = p.readDefaultWithToken(preferences);

    final _model = Model(
      convexServerUri: convexWorldUri,
      convexityAddress: convexityAddress,
      keyring: keyring,
      activeAddress: activeAddress,
      following: following,
      myTokens: myTokens,
      activities: activities,
      contacts: contacts,
      defaultWithToken: defaultWithToken,
    );

    logger.d(_model);

    context.read<AppState>().setState((_) => _model);
  } catch (e, s) {
    logger.e('$e $s');
  }
}

class AppState with ChangeNotifier {
  final client = http.Client();

  Model model;

  AppState({required this.model});

  ConvexClient convexClient() => ConvexClient(
        client: client,
        server: model.convexServerUri,
        credentials: model.activeAddress != null &&
                model.activeAccountKey != null &&
                model.activeKeyPair != null
            ? Credentials(
                address: model.activeAddress!,
                accountKey: model.activeAccountKey!,
                secretKey: model.activeKeyPair!.sk,
              )
            : null,
      );

  FungibleLibrary fungibleLibrary() =>
      FungibleLibrary(convexClient: convexClient());

  AssetLibrary assetLibrary() => AssetLibrary(convexClient: convexClient());

  TorusLibrary torus() => TorusLibrary(convexClient: convexClient());

  ConvexityClient convexityClient() => ConvexityClient(
        convexClient: convexClient(),
        actor: model.convexityAddress,
      );

  void setState(Model f(Model? m)) {
    model = f(model);

    notifyListeners();
  }

  void setFollowing(Set<AAsset?> following, {bool isPersistent = false}) {
    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeFollowing(preferences, following),
      );
    }

    setState((m) => m!.copyWith(following: Set<AAsset>.from(following)));
  }

  void follow(AAsset aasset, {bool isPersistent = true}) {
    var following = Set<AAsset?>.from(model.following)..add(aasset);

    setFollowing(following, isPersistent: isPersistent);
  }

  void unfollow(AAsset? aasset, {bool isPersistent = false}) {
    var following = model.following.where((e) => e != aasset).toSet();

    setFollowing(following, isPersistent: isPersistent);
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
      (model) => model!.copyWith(
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
      (model) => model!.copyWith(
        activities: activities,
      ),
    );
  }

  /// Add a new Contact to Address Book.
  void addContact(Contact contact, {bool isPersistent = true}) {
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
      (model) => model!.copyWith(
        contacts: contacts,
      ),
    );
  }

  /// Remove Contact from Address Book.
  void removeContact(Contact? contact, {bool isPersistent = false}) {
    var contacts = Set<Contact>.from(model.contacts);
    contacts.remove(contact);

    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeContacts(preferences, contacts),
      );
    }

    setState(
      (model) => model!.copyWith(
        contacts: contacts,
      ),
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

      Navigator.popUntil(context, ModalRoute.withName(route.LAUNCHER));
    });
  }

  Contact? findContact(Address? address) => model.contacts.firstWhereOrNull(
        (_contact) => _contact.address == address,
      );

  bool isAddressMine2(Address? address) => model.keyring.containsKey(address);

  void addToKeyring({
    required Address address,
    required KeyPair keyPair,
    bool isPersistent = true,
  }) {
    final _keyring = Map<Address, KeyPair>.from(model.keyring);
    _keyring[address] = keyPair;

    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeKeyring(preferences, _keyring),
      );
    }

    setState((m) {
      return m!.copyWith(keyring: _keyring);
    });
  }

  void removeAddress(Address? address, {bool isPersistent = true}) {
    final _keyring = Map<Address, KeyPair>.from(model.keyring)..remove(address);

    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeKeyring(preferences, _keyring),
      );
    }

    setState(
      (m) {
        return m!.copyWith(keyring: _keyring);
      },
    );
  }

  void setActiveAddress(
    Address? address, {
    bool isPersistent = true,
  }) {
    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeActiveAddress(preferences, address!),
      );
    }

    setState((m) => m!.copyWith(activeAddress: address));
  }

  void setDefaultWithToken(
    FungibleToken? defaultWithToken, {
    bool isPersistent = true,
  }) {
    if (isPersistent) {
      SharedPreferences.getInstance().then(
        (preferences) => p.writeDefaultWithToken(preferences, defaultWithToken),
      );
    }

    setState((m) => m!.copyWith2(defaultWithToken: () => defaultWithToken));
  }
}
