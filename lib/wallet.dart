import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _walletPreferencesKey = 'wallet';
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

  List<String> wallet = preferences.getStringList(_walletPreferencesKey) ?? [];

  wallet.add(encodeKeyPair(keyPair));

  return preferences.setStringList(_walletPreferencesKey, wallet);
}

Future<bool> select(KeyPair keyPair) async {
  var preferences = await SharedPreferences.getInstance();

  return preferences.setString(_activeKeyPair, encodeKeyPair(keyPair));
}

Future<List<KeyPair>> keyPairs() async {
  var preferences = await SharedPreferences.getInstance();

  List<String> wallet = preferences.getStringList(_walletPreferencesKey) ?? [];

  return wallet.map(decodeKeyPair).toList();
}

Future<KeyPair> active() async {
  var preferences = await SharedPreferences.getInstance();

  var s = preferences.getString(_activeKeyPair);

  if (s != null) {
    return decodeKeyPair(s);
  }

  return null;
}

class ActiveAndAll {
  final KeyPair active;
  final List<KeyPair> all;

  ActiveAndAll(this.active, this.all);
}

Future<ActiveAndAll> activeAndAll() async {
  var preferences = await SharedPreferences.getInstance();

  var active = preferences.getString(_activeKeyPair);

  var all = preferences.getStringList(_walletPreferencesKey) ?? [];

  return ActiveAndAll(
    active != null ? decodeKeyPair(active) : null,
    all.map(decodeKeyPair).toList(),
  );
}
