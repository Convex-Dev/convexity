import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

const prefFollowing = 'following';

Set<AssetMetadata> following(SharedPreferences preferences) {
  var encoded = preferences.getString(prefFollowing);

  if (encoded != null) {
    var v = jsonDecode(encoded) as List;
    var t = v.map((json) => FungibleTokenMetadata.fromJson(json));
    return t.toSet();
  }

  return Set<AssetMetadata>.identity();
}
