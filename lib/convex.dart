import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

const convexWorldHost = 'convex.world';

enum Lang {
  convexLisp,
  convexScript,
}

String langString(Lang lang) {
  var _lang;

  switch (lang) {
    case Lang.convexLisp:
      _lang = 'convex-lisp';
      break;
    case Lang.convexScript:
      _lang = 'convex-scrypt';
      break;
  }

  return _lang;
}

Future<http.Response> query({
  http.Client client,
  String scheme = 'https',
  String host = convexWorldHost,
  int port = 443,
  String source,
  String address,
  Lang lang = Lang.convexLisp,
}) {
  var uri = Uri(scheme: scheme, host: host, port: port, path: 'api/v1/query');

  var body = convert.jsonEncode({
    'source': source,
    'address': address,
    'lang': langString(lang),
  });

  if (client == null) {
    return http.post(uri, body: body);
  }

  return client.post(uri, body: body);
}
