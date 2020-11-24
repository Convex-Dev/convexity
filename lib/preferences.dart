import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

const PREF_FOLLOWING = 'following';

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
