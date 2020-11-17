import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'convex.dart';

abstract class Token {
  Map<String, dynamic> toJson();
}

@immutable
class FungibleToken extends Token {
  final Address address;
  final String name;
  final String description;
  final String symbol;
  final int decimals;

  FungibleToken({
    @required this.address,
    @required this.name,
    @required this.description,
    @required this.symbol,
    @required this.decimals,
  });

  @override
  bool operator ==(o) => o is FungibleToken && o.address == address;

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

  static FungibleToken fromJson(Map<String, dynamic> json) => FungibleToken(
        address: Address.fromJson(json['address']),
        name: json['name'],
        description: json['description'],
        symbol: json['symbol'],
        decimals: json['decimals'],
      );
}

@immutable
class NonFungibleToken extends Token {
  final Address address;
  final String name;
  final String description;
  final List<Object> coll;

  NonFungibleToken({
    @required this.address,
    @required this.name,
    @required this.description,
    @required this.coll,
  });

  @override
  Map<String, dynamic> toJson() => {};
}

@immutable
class Model {
  final KeyPair activeKeyPair;
  final List<KeyPair> allKeyPairs;
  final Set<Token> following;

  Model({
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
    activeKeyPair,
    allKeyPairs,
    following,
  }) =>
      Model(
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

  void setFollowing(Set<Token> following, {bool isPersistent = false}) {
    if (isPersistent) {
      var followingEncoded = jsonEncode(following.toList());

      SharedPreferences.getInstance().then(
        (preferences) =>
            preferences.setString(_prefFollowing, followingEncoded),
      );
    }

    setState((m) => m.copyWith(following: Set<Token>.from(following)));
  }

  void setActiveKeyPair(KeyPair active) {
    setState((m) => m.copyWith(activeKeyPair: active));
  }

  void setKeyPairs(List<KeyPair> keyPairs) {
    setState(
      (m) => m.copyWith(allKeyPairs: keyPairs),
    );
  }

  void addKeyPair(KeyPair k) {
    setState(
      (m) => m.copyWith(allKeyPairs: List<KeyPair>.from(m.allKeyPairs)..add(k)),
    );
  }

  void reset() {
    setState(
      (m) => Model(),
    );
  }
}
