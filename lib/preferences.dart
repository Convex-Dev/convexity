import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

const PREF_FOLLOWING = 'following';

Set<AAsset> readFollowing(SharedPreferences preferences) {
  var encoded = preferences.getString(PREF_FOLLOWING);

  if (encoded != null) {
    var l = jsonDecode(encoded) as List;
    var t = l.map((m) {});
    return t.toSet();
  }

  return Set<AAsset>.identity();
}

/// Persists the set of following Assets.
///
/// `following` will be persisted as a JSON encoded string.
void writeFollowing(SharedPreferences preferences, Set<AAsset> following) {
  // Converts to list before encoding because the encoder
  // doesn't seem to know how to handle sets - lists are fine though.
  var encoded = jsonEncode(following.toList());

  preferences.setString(PREF_FOLLOWING, encoded);
}
