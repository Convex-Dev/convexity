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

Future<bool> setActiveKeyPair(KeyPair keyPair) async {
  var preferences = await SharedPreferences.getInstance();

  return preferences.setString(_activeKeyPair, encodeKeyPair(keyPair));
}

List<KeyPair> allKeyPairs(SharedPreferences preferences) {
  List<String> wallet = preferences.getStringList(_allKeyPairs) ?? [];

  return wallet.map(decodeKeyPair).toList();
}

KeyPair activeKeyPair(SharedPreferences preferences) {
  var s = preferences.getString(_activeKeyPair);

  if (s != null) {
    return decodeKeyPair(s);
  }

  return null;
}
