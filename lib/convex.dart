import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:meta/meta.dart';

import 'config.dart' as config;
import 'logger.dart';

const CONVEX_WORLD_HOST = 'convex.world';

final convexWorldUri = Uri.parse('https://convex.world');

enum Lang {
  convexLisp,
  convexScript,
}

class Address2 {
  final int value;

  Address2(this.value);

  Address2.fromStr(String s) : value = int.parse(s.replaceAll('#', ''));

  Address2.fromJson(Map<String, dynamic> m) : value = (m['value'] as int);

  @override
  String toString() {
    return '#$value';
  }

  @override
  bool operator ==(o) => o is Address2 && o.value == value;

  @override
  int get hashCode => value.hashCode;

  Map<String, dynamic> toJson() => {'value': value};
}

class AccountKey {
  final String value;

  AccountKey(this.value);

  AccountKey.fromBin(Uint8List bin) : value = sodium.Sodium.bin2hex(bin);

  Uint8List toBin() => sodium.Sodium.hex2bin(value);

  @override
  String toString() => value;
}

enum AccountType {
  user,
  library,
  actor,
}

// ignore: missing_return
AccountType accountType(String s) {
  switch (s.toLowerCase()) {
    case "user":
      return AccountType.user;
    case "library":
      return AccountType.library;
    case "actor":
      return AccountType.actor;
  }
}

class Account {
  final int sequence;
  final Address2 address2;
  final AccountType type;
  final int balance;
  final int memorySize;
  final int memoryAllowance;

  Account({
    this.sequence,
    this.address2,
    this.balance,
    this.type,
    this.memorySize,
    this.memoryAllowance,
  });

  static Account fromJson(String json) {
    var m = convert.jsonDecode(json);

    return Account(
      sequence: m['sequence'],
      address2: Address2(m['address']),
      balance: m['balance'],
      type: accountType(m['type']),
      memorySize: m['memorySize'],
      memoryAllowance: m['allowance'],
    );
  }
}

sodium.KeyPair randomKeyPair() => sodium.CryptoSign.randomKeys();

Uint8List sign(Uint8List hash, Uint8List secretKey) =>
    sodium.CryptoSign.signDetached(hash, secretKey);

String langString(Lang lang) {
  switch (lang) {
    case Lang.convexLisp:
      return 'convexLisp';
    case Lang.convexScript:
      return 'convexScrypt';
  }

  return '';
}

Future<http.Response> queryRaw({
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
  final int id;
  final dynamic value;
  final String errorCode;

  Result({
    this.id,
    this.value,
    this.errorCode,
  });

  @override
  String toString() {
    return 'Result[id: $id, errorCode: $errorCode, value: $value]';
  }
}

Future<Result> transact2({
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

  if (prepareResponse.statusCode != 200) {
    throw Exception(prepareBody['error']['message']);
  }

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

Future<http.Response> getAccountRaw2({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  Address2 address,
}) {
  var uri = Uri(
    scheme: scheme,
    host: host,
    port: port,
    path: 'api/v1/accounts/${address.value}',
  );

  if (client == null) {
    return http.get(uri);
  }

  return client.get(uri);
}

Future<Account> getAccount2({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  Address2 address,
}) async {
  var response = await getAccountRaw2(
    client: client,
    scheme: scheme,
    host: host,
    port: port,
    address: address,
  );

  if (response.statusCode != 200) {
    return null;
  }

  if (config.isDebug()) {
    logger.d(response.body);
  }

  return Account.fromJson(response.body);
}

Future<http.Response> faucet({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  String address,
  int amount,
}) {
  var uri = Uri(
    scheme: scheme,
    host: host,
    port: port,
    path: 'api/v1/faucet',
  );

  var body = convert.jsonEncode({
    'address': address,
    'amount': amount,
  });

  if (client == null) {
    return http.post(uri, body: body);
  }

  return client.post(uri, body: body);
}

class ConvexClient {
  final Uri server;
  final http.Client client;

  ConvexClient({
    @required this.server,
    @required this.client,
  });

  Uri _uri(String path) => Uri(
        scheme: server.scheme,
        host: server.host,
        port: server.port,
        path: path,
      );

  Future<http.Response> prepareTransaction2({
    @required Address2 address,
    @required String source,
    int sequence,
    Lang lang = Lang.convexLisp,
  }) {
    final uri = _uri('api/v1/transaction/prepare');

    Map<String, dynamic> body = {
      'source': source,
      'address': address.value,
      'lang': langString(lang),
    };

    if (sequence != null) {
      body['sequence'] = sequence;
    }

    final bodyEncoded = convert.jsonEncode(body);

    if (config.isDebug()) {
      logger.d(body);
    }

    return client.post(uri, body: bodyEncoded);
  }

  Future<http.Response> submitTransaction2({
    @required Address2 address,
    @required AccountKey accountKey,
    @required String hash,
    @required String sig,
  }) {
    final uri = _uri('api/v1/transaction/submit');

    Map<String, dynamic> body = {
      'address': address.value,
      'accountKey': accountKey.value,
      'hash': hash,
      'sig': sig,
    };

    final bodyEncoded = convert.jsonEncode(body);

    if (config.isDebug()) {
      logger.d(body);
    }

    return client.post(uri, body: bodyEncoded);
  }

  Future<Result> prepareTransact({
    @required Address2 address,
    @required String source,
    @required AccountKey accountKey,
    @required Uint8List secretKey,
    int sequence,
    Lang lang = Lang.convexLisp,
  }) async {
    var prepareResponse = await prepareTransaction2(
      source: source,
      address: address,
      sequence: sequence,
      lang: lang,
    );

    var prepareBody = convert.jsonDecode(prepareResponse.body);

    if (prepareResponse.statusCode != 200) {
      throw Exception(prepareBody['errorCode']);
    }

    var hashHex = prepareBody['hash'];
    var hashBin = sodium.Sodium.hex2bin(hashHex);

    var sigBin = sign(hashBin, secretKey);
    var sigHex = sodium.Sodium.bin2hex(sigBin);

    var submitResponse = await submitTransaction2(
      address: address,
      accountKey: accountKey,
      hash: hashHex,
      sig: sigHex,
    );

    var submitBody = convert.jsonDecode(submitResponse.body);

    if (submitResponse.statusCode != 200) {
      throw Exception(submitBody['errorCode']);
    }

    return Result(
      value: submitBody['value'],
      errorCode: submitBody['errorCode'],
    );
  }

  Future<Address2> createAccount({@required AccountKey accountKey}) async {
    final body = convert.jsonEncode({
      'accountKey': accountKey.value,
    });

    if (config.isDebug()) {
      logger.d(body);
    }

    final response = await client.post(
      _uri('api/v1/createAccount'),
      body: body,
    );

    if (response.statusCode != 200) {
      logger.e(
        'Failed to create Account: ${response.body}',
      );

      return null;
    }

    var bodyDecoded = convert.jsonDecode(response.body);

    if (config.isDebug()) {
      logger.d(bodyDecoded);
    }

    final address = Address2(bodyDecoded['address'] as int);

    return address;
  }

  Future<http.Response> faucet2({
    @required Address2 address,
    @required int amount,
  }) async {
    final uri = _uri('api/v1/faucet');

    var body = convert.jsonEncode({
      'address': address.value,
      'amount': amount,
    });

    if (config.isDebug()) {
      logger.d(body);
    }

    return client.post(uri, body: body);
  }

  /// **Executes code on the Convex Network just to compute the result.**
  Future<Result> query2({
    @required String source,
    Address2 address,
    Lang lang = Lang.convexLisp,
  }) async {
    final uri = _uri('api/v1/query');

    var body = convert.jsonEncode({
      'source': source,
      'address': address?.value,
      'lang': langString(lang),
    });

    if (config.isDebug()) {
      logger.d(body);
    }

    var response = await client.post(uri, body: body);

    var responseDecoded = convert.jsonDecode(response.body);

    if (config.isDebug()) {
      logger.d(responseDecoded);
    }

    var resultValue = responseDecoded['value'];
    var resultErrorCode = responseDecoded['errorCode'];

    if (resultErrorCode != null) {
      logger.w('Query Result has an error: $resultErrorCode');
    }

    return Result(
      value: resultValue,
      errorCode: resultErrorCode,
    );
  }

  Future<Account> account2({
    @required Address2 address,
  }) =>
      getAccount2(
        client: client,
        scheme: server.scheme,
        host: server.host,
        port: server.port,
        address: address,
      );
}

abstract class Asset {}

@immutable
class FungibleTokenMetadata {
  final String name;
  final String description;
  final String symbol;
  final String currencySymbol;
  final int decimals;

  FungibleTokenMetadata({
    @required this.name,
    @required this.description,
    @required this.symbol,
    @required this.currencySymbol,
    @required this.decimals,
  });

  FungibleTokenMetadata.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        description = json['description'],
        symbol = json['symbol'],
        currencySymbol = json['currency-symbol'],
        decimals = json['decimals'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'symbol': symbol,
        'currency-symbol': currencySymbol,
        'decimals': decimals,
      };

  @override
  String toString() {
    return toJson().toString();
  }
}

@immutable
class FungibleToken implements Asset {
  final Address2 address;
  final FungibleTokenMetadata metadata;

  FungibleToken({
    @required this.address,
    @required this.metadata,
  });

  FungibleToken.fromJson(Map<String, dynamic> json)
      : address = Address2.fromJson(json['address']),
        metadata = FungibleTokenMetadata.fromJson(json['metadata']);

  Map<String, dynamic> toJson() => {
        'address': address.toJson(),
        'metadata': metadata.toJson(),
      };

  @override
  bool operator ==(o) => o is FungibleToken && o.address == address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() {
    return toJson().toString();
  }
}

@immutable
class NonFungibleTokenMetadata implements Asset {
  final String name;
  final String description;

  NonFungibleTokenMetadata({
    @required this.name,
    @required this.description,
  });

  NonFungibleTokenMetadata.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        description = json['description'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };

  @override
  String toString() {
    return toJson().toString();
  }
}

@immutable
class NonFungibleToken implements Asset {
  final Address2 address;
  final NonFungibleTokenMetadata metadata;

  NonFungibleToken({
    @required this.address,
    @required this.metadata,
  });

  NonFungibleToken.fromJson(Map<String, dynamic> json)
      : address = Address2.fromJson(json['address']),
        metadata = NonFungibleTokenMetadata.fromJson(json['metadata']);

  Map<String, dynamic> toJson() => {
        'address': address.toJson(),
        'metadata': metadata.toJson(),
      };

  @override
  bool operator ==(o) => o is NonFungibleToken && o.address == address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() {
    return toJson().toString();
  }
}

@immutable
class NonFungibleItemPolicy {}

@immutable
class NonFungibleItem {
  final int id;
  final Map<String, dynamic> data;
  final NonFungibleItemPolicy policy;

  NonFungibleItem({
    this.id,
    this.data,
    this.policy,
  });
}

class FungibleLibrary {
  final ConvexClient convexClient;

  FungibleLibrary({@required this.convexClient});

  /// **Executes a Fungible transfer Transaction on the Convex Network.**
  ///
  /// The interface is a bit complicated since a Transaction is executed in two phases:
  ///
  /// **1. Prepare**
  ///
  /// It's the process of sending 'what' we want to execute on the Convex Network.
  /// It returns a hash which uniquely identifies our Transaction.
  ///
  /// **2. Submit**
  ///
  /// It's the process of signing the data with a private key and generated hash in the prepare step,
  /// and sending the code one more time to 'commit' the Transaction.
  Future<Result> transfer({
    @required Address2 token,
    @required Address2 holder,
    @required AccountKey holderAccountKey,
    @required Uint8List holderSecretKey,
    @required Address2 receiver,
    @required int amount,
  }) =>
      convexClient.prepareTransact(
        address: holder,
        secretKey: holderSecretKey,
        accountKey: holderAccountKey,
        source: '(import convex.fungible :as fungible)'
            '(fungible/transfer $token $receiver $amount)',
      );

  /// **Creates (deploys) a Fungible Token on the Convex Network.**
  ///
  /// Returns the Address of the deployed Token.
  Future<Result> createToken({
    @required Address2 holder,
    @required AccountKey accountKey,
    @required Uint8List secretKey,
    @required int supply,
  }) =>
      convexClient.prepareTransact(
        address: holder,
        accountKey: accountKey,
        secretKey: secretKey,
        source: '(import convex.fungible :as fungible)'
            '(deploy (fungible/build-token {:supply $supply}))',
      );
}

class NonFungibleLibrary {
  final ConvexClient convexClient;

  NonFungibleLibrary({@required this.convexClient});

  Future<Result> createToken({
    @required Address2 caller,
    @required AccountKey callerAccountKey,
    @required Uint8List callerSecretKey,
    Map<String, dynamic> attributes,
  }) {
    final _attributes = attributes ?? {};

    final _name = _attributes['name'] as String ?? 'No name';
    final _uri = _attributes['uri'] as String;

    final _data = '{'
        ':name "$_name",'
        ':uri "$_uri",'
        ':extra {}'
        '}';

    var _source = '(import convex.nft-tokens :as nft)'
        '(deploy (nft/create-token $_data nil) )';

    return convexClient.prepareTransact(
      address: caller,
      accountKey: callerAccountKey,
      secretKey: callerSecretKey,
      source: _source,
    );
  }
}

class AssetLibrary {
  final ConvexClient convexClient;

  AssetLibrary({@required this.convexClient});

  /// Balance is based on the type of Asset.
  /// It returns a number for Fungible Tokens,
  /// but a set of numbers (IDs) for Non-Fungible Tokens.
  Future<dynamic> balance({
    @required Address2 asset,
    @required Address2 owner,
  }) async {
    var source = '(import convex.asset :as asset)'
        '(asset/balance $asset $owner)';

    var result = await convexClient.query2(source: source);

    if (result.errorCode != null) {
      logger.e('Failed to query balance: ${result.value}');

      return null;
    }

    return result.value;
  }

  Future<Result> transferNonFungible({
    @required Address2 holder,
    @required Uint8List holderSecretKey,
    @required AccountKey holderAccountKey,
    @required Address2 receiver,
    @required Address2 nft,
    @required Set<int> tokens,
  }) {
    var _source = '(import convex.asset :as asset)'
        '(asset/transfer $receiver [ $nft, #{ ${tokens.join(",")} } ])';

    return convexClient.prepareTransact(
      address: holder,
      accountKey: holderAccountKey,
      secretKey: holderSecretKey,
      source: _source,
    );
  }

  Future<Result> transferFungible({
    @required Address2 holder,
    @required AccountKey holderAccountKey,
    @required Uint8List holderSecretKey,
    @required Address2 receiver,
    @required Address2 token,
    @required double amount,
  }) {
    var _source = '(import convex.asset :as asset)'
        '(asset/transfer $receiver [ $token, $amount ])';

    return convexClient.prepareTransact(
      address: holder,
      accountKey: holderAccountKey,
      secretKey: holderSecretKey,
      source: _source,
    );
  }
}
