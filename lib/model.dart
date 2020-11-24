import 'dart:convert';
import 'dart:developer';

import 'package:convex_wallet/convexity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'convex.dart';

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

  Map<String, dynamic> toMap() => {
        'type': type.toString(),
        'asset': asset.toMap(),
      };

  String toJson() => jsonEncode(toMap());

  static AAsset fromMap(Map<String, dynamic> m) {
    var type = assetType(m['type']);

    var asset;

    if (type == AssetType.fungible) {
      asset = FungibleToken.fromMap(m['asset']);
    }

    return AAsset(
      type: type,
      asset: asset,
    );
  }
}

@immutable
class FungibleToken {
  final Address address;
  final FungibleTokenMetadata metadata;

  FungibleToken({
    @required this.address,
    @required this.metadata,
  });

  FungibleToken.fromMap(Map<String, dynamic> m)
      : address = Address.fromMap(m['address']),
        metadata = FungibleTokenMetadata.fromMap(m['metadata']);

  Map<String, dynamic> toMap() => {
        'address': address.toMap(),
        'metadata': metadata.toMap(),
      };

  @override
  bool operator ==(o) => o is FungibleToken && o.address == address;

  @override
  int get hashCode => address.hex.hashCode;

  @override
  String toString() {
    return toMap().toString();
  }
}

@immutable
class FungibleTokenMetadata {
  final String name;
  final String description;
  final String symbol;
  final int decimals;

  FungibleTokenMetadata({
    @required this.name,
    @required this.description,
    @required this.symbol,
    @required this.decimals,
  });

  FungibleTokenMetadata.fromMap(Map<String, dynamic> m)
      : name = m['name'],
        description = m['description'],
        symbol = m['symbol'],
        decimals = m['decimals'];

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'symbol': symbol,
        'decimals': decimals,
      };

  @override
  String toString() {
    return toMap().toString();
  }
}

final convexWorldUri = Uri.parse('https://convex.world');

@immutable
class Model {
  final Uri convexServerUri;
  final Address convexityAddress;
  final KeyPair activeKeyPair;
  final List<KeyPair> allKeyPairs;
  final Set<AAsset> following;

  Model({
    this.convexServerUri,
    this.convexityAddress,
    this.activeKeyPair,
    this.allKeyPairs = const [],
    this.following = const {},
  });

  String get activeAddress =>
      activeKeyPair != null ? Sodium.bin2hex(activeKeyPair.pk) : null;

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
  }) =>
      Model(
        convexServerUri: convexServerUri ?? this.convexServerUri,
        convexityAddress: convexityAddress ?? this.convexityAddress,
        activeKeyPair: activeKeyPair ?? this.activeKeyPair,
        allKeyPairs: allKeyPairs ?? this.allKeyPairs,
        following: following ?? this.following,
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

  String _prefFollowing = 'following';

  AppState({this.model});

  Convexity convexity() {
    return Convexity(
      convexServerUri: model.convexServerUri,
      actorAddress: model.convexityAddress,
    );
  }

  void setState(Model f(Model m)) {
    model = f(model);

    log(
      '*STATE*\n'
      '-------\n'
      '$model\n'
      '---------------------------------\n',
    );

    notifyListeners();
  }

  void setFollowing(Set<AAsset> following, {bool isPersistent = false}) {
    if (isPersistent) {
      var followingEncoded = jsonEncode(following.toList());

      SharedPreferences.getInstance().then(
        (preferences) =>
            preferences.setString(_prefFollowing, followingEncoded),
      );
    }

    setState((m) => m.copyWith(following: Set<AAsset>.from(following)));
  }

  void follow(AAsset aasset, {bool isPersistent = false}) {
    var following = Set<AAsset>.from(model.following)..add(aasset);

    setFollowing(following, isPersistent: isPersistent);
  }

  void setActiveKeyPair(KeyPair active) {
    setState((m) => m.copyWith(activeKeyPair: active));
  }

  void setKeyPairs(List<KeyPair> keyPairs) {
    setState(
      (m) => m.copyWith(allKeyPairs: keyPairs),
    );
  }

  /// Add a new KeyPair `k`, and persist it to disk if `isPersistent` is true.
  ///
  /// This method is usually called whenever a new Account is created.
  void addKeyPair(KeyPair k, {bool isPersistent = false}) {
    setState(
      (m) => m.copyWith(allKeyPairs: List<KeyPair>.from(m.allKeyPairs)..add(k)),
    );
  }

  /// Reset app state.
  void reset() {
    setState(
      (m) => Model(),
    );
  }
}
