import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

const prefFollowing = 'following';

Set<Token> following(SharedPreferences preferences) {
  var encoded = preferences.getString(prefFollowing);

  if (encoded != null) {
    var v = jsonDecode(encoded) as List;
    var t = v.map((json) => FungibleToken.fromJson(json));
    return t.toSet();
  }

  return Set<Token>.identity();
}
