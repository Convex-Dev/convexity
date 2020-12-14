import 'dart:convert';

import 'package:convex_wallet/logger.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

const PREF_FOLLOWING = 'FOLLOWING';
const PREF_ALL_KEYPAIRS = 'ALL_KEYPAIRS';
const PREF_ACTIVE_KEYPAIR = 'ACTIVE_KEYPAIR';
const PREF_MY_TOKENS = 'MY_TOKENS';
const PREF_ACTIVITIES = 'ACTIVITIES';
const PREF_CONTACTS = 'CONTACTS';

String encodeKeyPair(KeyPair keyPair) =>
    '${Sodium.bin2hex(keyPair.pk)};${Sodium.bin2hex(keyPair.sk)}';

KeyPair decodeKeyPair(String s) {
  var keys = s.split(';');

  return KeyPair(
    pk: Sodium.hex2bin(keys[0]),
    sk: Sodium.hex2bin(keys[1]),
  );
}

/// Persists a new KeyPair.
///
/// Adds to the existing list of KeyPairs.
void addKeyPair(SharedPreferences preferences, KeyPair keyPair) {
  List<String> wallet = preferences.getStringList(PREF_ALL_KEYPAIRS) ?? [];

  wallet.add(encodeKeyPair(keyPair));

  preferences.setStringList(PREF_ALL_KEYPAIRS, wallet);
}

/// Persists the active KeyPair.
void setActiveKeyPair(SharedPreferences preferences, KeyPair keyPair) {
  preferences.setString(PREF_ACTIVE_KEYPAIR, encodeKeyPair(keyPair));
}

/// Returns a list of persisted KeyPairs.
List<KeyPair> allKeyPairs(SharedPreferences preferences) {
  List<String> wallet = preferences.getStringList(PREF_ALL_KEYPAIRS) ?? [];

  return wallet.map(decodeKeyPair).toList();
}

/// Returns the active KeyPair, or null if there isn't one.
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
/// [following] will be persisted as a JSON encoded string.
void writeFollowing(SharedPreferences preferences, Set<AAsset> following) {
  var encoded = jsonEncode(following.toList());

  preferences.setString(PREF_FOLLOWING, encoded);
}

/// Persists My Tokens.
///
/// [myTokens] will be persisted as a JSON encoded string.
Future<bool> writeMyTokens(
  SharedPreferences preferences,
  Iterable<AAsset> myTokens,
) {
  var encoded = jsonEncode(myTokens.toList());

  return preferences.setString(PREF_MY_TOKENS, encoded);
}

/// Reads My Tokens.
///
/// Returns an empty set if there is none.
Set<AAsset> readMyTokens(SharedPreferences preferences) {
  var encoded = preferences.getString(PREF_MY_TOKENS);

  if (encoded != null) {
    var l = jsonDecode(encoded) as List;

    return l.map((m) => AAsset.fromJson(m)).toSet();
  }

  return Set<AAsset>.identity();
}

/// Persists Activities.
///
/// [activities] will be persisted as a JSON encoded string.
Future<bool> writeActivities(
  SharedPreferences preferences,
  Iterable<Activity> activities,
) {
  var encoded = jsonEncode(activities.toList());

  logger.d('Write Activities: $encoded');

  return preferences.setString(PREF_ACTIVITIES, encoded);
}

/// Reads Activities.
///
/// Returns an empty list if there is none.
List<Activity> readActivities(SharedPreferences preferences) {
  var encoded = preferences.getString(PREF_ACTIVITIES);

  if (encoded != null) {
    var l = jsonDecode(encoded) as List;

    return l.map((m) => Activity.fromJson(m)).toList();
  }

  return List.empty();
}

/// Reads the set of [Contact].
///
/// Returns an empty set if there is none.
Set<Contact> readContacts(SharedPreferences preferences) {
  var encoded = preferences.getString(PREF_CONTACTS);

  if (encoded != null) {
    var l = jsonDecode(encoded) as List;

    return l.map((m) => Contact.fromJson(m)).toSet();
  }

  return Set<Contact>.identity();
}

/// Persists [Contact]s.
///
/// [contacts] will be persisted as a JSON encoded string.
Future<bool> writeContacts(
  SharedPreferences preferences,
  Iterable<Contact> contacts,
) {
  var encoded = jsonEncode(contacts.toList());

  logger.d('Write Contacts: $encoded');

  return preferences.setString(PREF_CONTACTS, encoded);
}
