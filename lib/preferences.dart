import 'dart:convert';

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

const PREF_FOLLOWING = 'following';
const PREF_ALL_KEYPAIRS = 'allKeyPairs';
const PREF_ACTIVE_KEYPAIR = 'activeKeyPair';

String encodeKeyPair(KeyPair keyPair) =>
    '${Sodium.bin2hex(keyPair.pk)};${Sodium.bin2hex(keyPair.sk)}';

KeyPair decodeKeyPair(String s) {
  var keys = s.split(';');

  return KeyPair(
    pk: Sodium.hex2bin(keys[0]),
    sk: Sodium.hex2bin(keys[1]),
  );
}

void addKeyPair(SharedPreferences preferences, KeyPair keyPair) {
  List<String> wallet = preferences.getStringList(PREF_ALL_KEYPAIRS) ?? [];

  wallet.add(encodeKeyPair(keyPair));

  preferences.setStringList(PREF_ALL_KEYPAIRS, wallet);
}

void setActiveKeyPair(SharedPreferences preferences, KeyPair keyPair) {
  preferences.setString(PREF_ACTIVE_KEYPAIR, encodeKeyPair(keyPair));
}

List<KeyPair> allKeyPairs(SharedPreferences preferences) {
  List<String> wallet = preferences.getStringList(PREF_ALL_KEYPAIRS) ?? [];

  return wallet.map(decodeKeyPair).toList();
}

KeyPair activeKeyPair(SharedPreferences preferences) {
  var s = preferences.getString(PREF_ACTIVE_KEYPAIR);

  if (s != null) {
    return decodeKeyPair(s);
  }

  return null;
}

/// Reads the set of following Assets.
///
/// Returns an empty set if there is none.
Set<AAsset> readFollowing(SharedPreferences preferences) {
  var encoded = preferences.getString(PREF_FOLLOWING);

  if (encoded != null) {
    var l = jsonDecode(encoded) as List;

    return l.map((m) => AAsset.fromJson(m)).toSet();
  }

  return Set<AAsset>.identity();
}

/// Persists the set of following Assets.
///
/// `following` will be persisted as a JSON encoded string.
void writeFollowing(SharedPreferences preferences, Set<AAsset> following) {
  var encoded = jsonEncode(following.toList());

  preferences.setString(PREF_FOLLOWING, encoded);
}
