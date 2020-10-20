import 'dart:developer';

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _allKeyPairs = 'wallet';
const _activeKeyPair = 'activeKeyPair';

String encodeKeyPair(KeyPair keyPair) =>
    '${Sodium.bin2hex(keyPair.pk)};${Sodium.bin2hex(keyPair.sk)}';

KeyPair decodeKeyPair(String s) {
  var keys = s.split(';');

  return KeyPair(
    pk: Sodium.hex2bin(keys[0]),
    sk: Sodium.hex2bin(keys[1]),
  );
}

Future<bool> addKeyPair(KeyPair keyPair) async {
  var preferences = await SharedPreferences.getInstance();

  List<String> wallet = preferences.getStringList(_allKeyPairs) ?? [];

  wallet.add(encodeKeyPair(keyPair));

  return preferences.setStringList(_allKeyPairs, wallet);
}

Future<void> removeKeyPair(KeyPair keyPair) async {
  var preferences = await SharedPreferences.getInstance();

  var wallet = preferences.getStringList(_allKeyPairs) ?? [];

  // Remove KeyPair from Wallet.
  wallet.removeWhere((s) => s == encodeKeyPair(keyPair));

  // Replace persisted Wallet.
  preferences.setStringList(_allKeyPairs, wallet);

  // If this KeyPair is active, we have to:
  // - replace with the last KeyPair from Wallet (if there is one)
  // - or simply remove from storage.
  var active = preferences.getString(_activeKeyPair);

  var isRemovingActive = active == encodeKeyPair(keyPair);

  log('Remove KeyPair ${encodeKeyPair(keyPair)}. Active? $isRemovingActive');

  if (isRemovingActive) {
    if (wallet.isEmpty) {
      preferences.remove(_activeKeyPair);

      log('Removed the active KeyPair from Wallet.');
    } else {
      preferences.setString(_activeKeyPair, wallet.last);

      log('Replaced the active KeyPair with the last one from Wallet.');
    }
  }
}

Future<bool> setKeyPairs(List<KeyPair> keyPairs) async {
  var preferences = await SharedPreferences.getInstance();

  return preferences.setStringList(_allKeyPairs, keyPairs.map(encodeKeyPair));
}

Future<bool> setActive(KeyPair keyPair) async {
  var preferences = await SharedPreferences.getInstance();

  return preferences.setString(_activeKeyPair, encodeKeyPair(keyPair));
}

Future<List<KeyPair>> keyPairs() async {
  var preferences = await SharedPreferences.getInstance();

  List<String> wallet = preferences.getStringList(_allKeyPairs) ?? [];

  return wallet.map(decodeKeyPair).toList();
}

Future<KeyPair> activeKeyPair() async {
  var preferences = await SharedPreferences.getInstance();

  var s = preferences.getString(_activeKeyPair);

  if (s != null) {
    return decodeKeyPair(s);
  }

  return null;
}
