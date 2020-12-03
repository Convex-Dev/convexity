import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'convex.dart';
import 'convexity.dart';
import 'preferences.dart' as p;
import 'route.dart' as route;

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
    var type = assetType(json['type']);

    var asset;

    if (type == AssetType.fungible) {
      asset = FungibleToken.fromJson(json['asset']);
    }

    return AAsset(
      type: type,
      asset: asset,
    );
  }
}

enum AddressInputOption {
  textField,
  scan,
}

final convexWorldUri = Uri.parse('https://convex.world');

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

  const Model({
    this.convexServerUri,
    this.convexityAddress,
    this.activeKeyPair,
    this.allKeyPairs = const [],
    this.following = const {},
    this.myTokens = const {},
  });

  Address get activeAddress => activeKeyPair != null
      ? Address(hex: Sodium.bin2hex(activeKeyPair.pk))
      : null;

  KeyPair activeKeyPairOrDefault() {
    if (activeKeyPair != null) {
      return activeKeyPair;
    }

    return allKeyPairs.isNotEmpty ? allKeyPairs.last : null;
  }

  Model copyWith({
    Uri convexServerUri,
    Address convexityAddress,
    KeyPair activeKeyPair,
    List<KeyPair> allKeyPairs,
    Set<AAsset> following,
    Set<AAsset> myTokens,
  }) =>
      Model(
        convexServerUri: convexServerUri ?? this.convexServerUri,
        convexityAddress: convexityAddress ?? this.convexityAddress,
        activeKeyPair: activeKeyPair ?? this.activeKeyPair,
        allKeyPairs: allKeyPairs ?? this.allKeyPairs,
        following: following ?? this.following,
        myTokens: myTokens ?? this.myTokens,
      );

  String toString() {
    var activeKeyPairStr =
        'Active KeyPair: ${activeKeyPair != null ? Sodium.bin2hex(activeKeyPair.pk) : null}';

    var allKeyPairsStr =
        'All KeyPairs: ${allKeyPairs.map((e) => Sodium.bin2hex(e.pk))}';

    return [
      activeKeyPairStr,
      allKeyPairsStr,
      following.toList(),
    ].join('\n');
  }
}

class AppState with ChangeNotifier {
  Model model;

  AppState({this.model});

  ConvexClient convexClient() => ConvexClient(server: model.convexServerUri);

  FungibleClient fungibleClient() =>
      FungibleClient(convexClient: convexClient());

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

  /// Reset app state.
  void reset(BuildContext context) {
    SharedPreferences.getInstance().then((preferences) {
      preferences.clear();

      setState((m) => Model(convexServerUri: convexWorldUri));

      Navigator.popUntil(context, ModalRoute.withName(route.dev));
    });
  }
}
