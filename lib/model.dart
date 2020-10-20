import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

class Model {
  final KeyPair activeKeyPair;
  final List<KeyPair> allKeyPairs;

  Model({
    this.activeKeyPair,
    this.allKeyPairs = const [],
  });

  Model copyWith({
    activeKeyPair,
    allKeyPairs,
  }) =>
      Model(
        activeKeyPair: activeKeyPair ?? this.activeKeyPair,
        allKeyPairs: allKeyPairs ?? this.allKeyPairs,
      );

  String toString() {
    var activeKeyPairStr =
        'Active KeyPair: ${activeKeyPair != null ? Sodium.bin2hex(activeKeyPair.pk) : null}';

    var allKeyPairsStr =
        'All KeyPairs: ${allKeyPairs.map((e) => Sodium.bin2hex(e.pk))}';

    return [activeKeyPairStr, allKeyPairsStr].join('\n');
  }
}

class AppState with ChangeNotifier {
  Model model;

  AppState({this.model});

  void setState(Model f(Model m)) {
    model = f(model);

    log('STATE\n'
        '-----\n'
        '$model\n'
        '---------------------------------\n');

    notifyListeners();
  }

  KeyPair activeKeyPair() => model.activeKeyPair ?? model.allKeyPairs.last;

  void setActiveKeyPair(KeyPair active) {
    setState((m) => m.copyWith(activeKeyPair: active));
  }

  void addKeyPair(KeyPair k) {
    setState(
      (m) => m.copyWith(allKeyPairs: List<KeyPair>.from(m.allKeyPairs)..add(k)),
    );
  }

  void addKeyPairs(List<KeyPair> keyPairs) {
    setState(
      (m) => m.copyWith(
          allKeyPairs: List<KeyPair>.from(m.allKeyPairs)..addAll(keyPairs)),
    );
  }

  void dispose() {
    super.dispose();
  }
}
