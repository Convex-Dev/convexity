import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;

const CONVEX_WORLD_HOST = 'convex.world';

// -- Types

enum Lang {
  convexLisp,
  convexScript,
}

class Address {
  final String hex;

  Address({this.hex});
}

enum AccountType {
  user,
  library,
  actor,
}

class Account {
  final Address address;
  final int balance;
  final AccountType type;

  Account({this.address, this.balance, this.type});
}

sodium.KeyPair randomKeyPair() => sodium.CryptoSign.randomKeys();

Uint8List sign(Uint8List hash, Uint8List secretKey) =>
    sodium.CryptoSign.signDetached(hash, secretKey);

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
  String host = CONVEX_WORLD_HOST,
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

Future<http.Response> prepareTransaction({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  String source,
  String address,
  int sequenceNumber,
  Lang lang = Lang.convexLisp,
}) {
  var uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: 'api/v1/transaction/prepare');

  Map<String, dynamic> body = {
    'source': source,
    'address': address,
    'lang': langString(lang),
  };

  if (sequenceNumber != null) {
    body['sequenceNumber'] = sequenceNumber;
  }

  var bodyEncoded = convert.jsonEncode(body);

  if (client == null) {
    return http.post(uri, body: bodyEncoded);
  }

  return client.post(uri, body: bodyEncoded);
}

Future<http.Response> submitTransaction({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  String address,
  String hash,
  String sig,
}) {
  var uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: 'api/v1/transaction/submit');

  Map<String, dynamic> body = {
    'hash': hash,
    'address': address,
    'sig': sig,
  };

  var bodyEncoded = convert.jsonEncode(body);

  if (client == null) {
    return http.post(uri, body: bodyEncoded);
  }

  return client.post(uri, body: bodyEncoded);
}

class Result {
  Result({
    this.id,
    this.value,
    this.errorCode,
  });

  int id;
  dynamic value;
  String errorCode;
}

Future<Result> transact({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  String source,
  String address,
  int sequenceNumber,
  Lang lang = Lang.convexLisp,
  Uint8List secretKey,
}) async {
  var prepareResponse = await prepareTransaction(
    client: client,
    scheme: scheme,
    host: host,
    port: port,
    source: source,
    address: address,
    sequenceNumber: sequenceNumber,
    lang: lang,
  );

  var prepareBody = convert.jsonDecode(prepareResponse.body);

  var hashHex = prepareBody['hash'];
  var hashBin = sodium.Sodium.hex2bin(hashHex);

  var sigBin = sign(hashBin, secretKey);
  var sigHex = sodium.Sodium.bin2hex(sigBin);

  var submitResponse = await submitTransaction(
    client: client,
    scheme: scheme,
    host: host,
    port: port,
    address: address,
    hash: hashHex,
    sig: sigHex,
  );

  var submitBody = convert.jsonDecode(submitResponse.body);

  if (submitResponse.statusCode != 200) {
    throw Exception(submitBody['error']['message']);
  }

  return Result(
    id: submitBody['id'],
    value: submitBody['value'],
    errorCode: submitBody['error-code'],
  );
}

Future<http.Response> account({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  String address,
}) {
  var uri = Uri(
    scheme: scheme,
    host: host,
    port: port,
    path: 'api/v1/accounts/' + address,
  );

  if (client == null) {
    return http.get(uri);
  }

  return client.get(uri);
}

Future<http.Response> faucet({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  String address,
  int amount,
}) {
  var uri = Uri(scheme: scheme, host: host, port: port, path: 'api/v1/faucet');

  var body = convert.jsonEncode({
    'address': address,
    'amount': amount,
  });

  if (client == null) {
    return http.post(uri, body: body);
  }

  return client.post(uri, body: body);
}
