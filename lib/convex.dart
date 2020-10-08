import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

var authority = 'convex.world';

Future<http.Response> query(http.Client client,
    {String source, String address, String lang}) {
  var uri = Uri.https(authority, 'api/v1/query');

  var body = convert.jsonEncode({'source': source, 'address': address});

  return client.post(uri, body: body);
}
