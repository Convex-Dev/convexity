import 'dart:convert';

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';
import 'crypto.dart' as crypto;
import 'convex.dart';
import 'logger.dart';

const PREF_FOLLOWING = 'FOLLOWING';
const PREF_KEYRING = 'KEYRING';
const PREF_MY_TOKENS = 'MY_TOKENS';
const PREF_ACTIVITIES = 'ACTIVITIES';
const PREF_CONTACTS = 'CONTACTS';
const PREF_WHITELISTS = 'WHITELISTS';
const PREF_ACTIVE_ADDRESS = 'ACTIVE_ADDRESS';
const PREF_DEFAULT_WITH_TOKEN = 'DEFAULT_WITH_TOKEN';

String encodeKeyPair(KeyPair keyPair) =>
    '${Sodium.bin2hex(keyPair.pk)};${Sodium.bin2hex(keyPair.sk)}';

KeyPair decodeKeyPair(String s) {
  var keys = s.split(';');

  return KeyPair(
    pk: Sodium.hex2bin(keys[0]),
    sk: Sodium.hex2bin(keys[1]),
  );
}

Map<Address, KeyPair> readKeyring(SharedPreferences preferences) {
  final encoded = preferences.getString(PREF_KEYRING);

  logger.d(encoded);

  if (encoded != null) {
    return crypto.keyringFromJson(
      jsonDecode(preferences.getString(PREF_KEYRING)!),
    );
  }

  return {};
}

Future<bool> writeKeyring(
  SharedPreferences preferences,
  Map<Address?, KeyPair?> keyring,
) {
  final encoded = jsonEncode(crypto.keyringToJson(keyring ?? {}));

  logger.d(encoded);

  return preferences.setString(PREF_KEYRING, encoded);
}

/// Returns the active Address, or null if there isn't one.
Address? readActiveAddress(SharedPreferences preferences) {
  var encoded = preferences.getString(PREF_ACTIVE_ADDRESS);

  logger.d(encoded);

  if (encoded != null) {
    return Address.fromJson(jsonDecode(encoded));
  }

  return null;
}

/// Persists the active Address.
void writeActiveAddress(SharedPreferences preferences, Address activeAddress) {
  final encoded = jsonEncode(activeAddress.toJson());

  logger.d(encoded);

  preferences.setString(PREF_ACTIVE_ADDRESS, encoded);
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
void writeFollowing(SharedPreferences preferences, Set<AAsset?> following) {
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

/// Reads the default 'with Token'.
///
/// Returns null if there isn't a 'with Token' persisted.
FungibleToken? readDefaultWithToken(SharedPreferences preferences) {
  final encoded = preferences.getString(PREF_DEFAULT_WITH_TOKEN);

  if (encoded != null) {
    return FungibleToken.fromJson(jsonDecode(encoded));
  }

  return null;
}

/// Persists the default 'with Token'.
///
/// [defaultWithToken] will be persisted as a JSON encoded string.
Future<bool> writeDefaultWithToken(
  SharedPreferences preferences,
  FungibleToken? defaultWithToken,
) {
  if (defaultWithToken == null) {
    logger.d('Reset default with Token');

    return preferences.remove(PREF_DEFAULT_WITH_TOKEN);
  }

  final encoded = jsonEncode(defaultWithToken.toJson());

  logger.d('Write default with Token: $encoded');

  return preferences.setString(PREF_DEFAULT_WITH_TOKEN, encoded);
}
