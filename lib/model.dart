import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

class Model {
  final KeyPair activeKeyPair;
  final List<KeyPair> allKeyPairs;

  Model({
    this.activeKeyPair,
    this.allKeyPairs,
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

class ModelNotifier with ChangeNotifier {
  Model model;

  ModelNotifier({this.model});

  void setState(Model f(Model m)) {
    model = f(model);

    log('STATE\n-----\n$model\n---------------------------------');

    notifyListeners();
  }
}
