import 'dart:convert';
import 'dart:developer';

import 'package:convex_wallet/convexity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'convex.dart';
import 'config.dart' as config;

abstract class AssetMetadata {
  Map<String, dynamic> toJson();
}

@immutable
class FungibleTokenMetadata extends AssetMetadata {
  final Address address;
  final String name;
  final String description;
  final String symbol;
  final int decimals;

  FungibleTokenMetadata({
    @required this.address,
    @required this.name,
    @required this.description,
    @required this.symbol,
    @required this.decimals,
  });

  @override
  bool operator ==(o) => o is FungibleTokenMetadata && o.address == address;

  @override
  int get hashCode => address.hex.hashCode;

  @override
  String toString() {
    return '''FungibleToken:
      address: $address,
      name: $name, 
      description: $description,
      symbol: $symbol,
      decimals: $decimals''';
  }

  @override
  Map<String, dynamic> toJson() => {
        'address': address.toJson(),
        'name': name,
        'description': description,
        'symbol': symbol,
        'decimals': decimals,
      };

  static FungibleTokenMetadata fromJson(Map<String, dynamic> json) =>
      FungibleTokenMetadata(
        address: Address.fromJson(json['address']),
        name: json['name'],
        description: json['description'],
        symbol: json['symbol'],
        decimals: json['decimals'],
      );
}

@immutable
class NonFungibleTokenMetadata extends AssetMetadata {
  final Address address;
  final String name;
  final String description;
  final List<Object> coll;

  NonFungibleTokenMetadata({
    @required this.address,
    @required this.name,
    @required this.description,
    @required this.coll,
  });

  @override
  Map<String, dynamic> toJson() => {};
}

final convexWorldUri = Uri.parse('https://convex.world');

@immutable
class Model {
  final Uri convexServerUri;
  final Address convexityAddress;
  final KeyPair activeKeyPair;
  final List<KeyPair> allKeyPairs;
  final Set<AssetMetadata> following;

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
    Set<AssetMetadata> following,
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
    if (config.isDebug()) {
      log('''
        Convexity client: 
        convexServerUri ${model.convexServerUri}, 
        actorAddress ${model.convexityAddress}
      ''');
    }

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

  void setFollowing(Set<AssetMetadata> following, {bool isPersistent = false}) {
    if (isPersistent) {
      var followingEncoded = jsonEncode(following.toList());

      SharedPreferences.getInstance().then(
        (preferences) =>
            preferences.setString(_prefFollowing, followingEncoded),
      );
    }

    setState((m) => m.copyWith(following: Set<AssetMetadata>.from(following)));
  }

  void followAsset(AssetMetadata metadata, {bool isPersistent = false}) {
    var following = Set<AssetMetadata>.from(model.following)..add(metadata);

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
