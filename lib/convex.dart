import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:meta/meta.dart';

import 'config.dart' as config;
import 'logger.dart';

const CONVEX_WORLD_HOST = 'convex.world';

enum Lang {
  convexLisp,
  convexScript,
}

class Address2 {
  final int value;

  Address2(this.value);

  Address2.fromStr(String s) : value = int.parse(s);

  Address2.fromJson(Map<String, dynamic> m) : value = (m['value'] as int);

  @override
  String toString() {
    return '#$value';
  }
}

class AccountKey {
  final String value;

  AccountKey(this.value);

  AccountKey.fromBin(Uint8List bin) : value = sodium.Sodium.bin2hex(bin);

  Uint8List toBin() => sodium.Sodium.hex2bin(value);

  @override
  String toString() => value;
}

class Address {
  final String hex;

  Address.fromHex(String hex) : hex = Address.trim0x(hex).toLowerCase();

  Address.fromJson(Map<String, dynamic> m)
      : hex = Address.trim0x(m['hex']).toLowerCase();

  Address.fromKeyPair(
    sodium.KeyPair keyPair,
  ) : hex = sodium.Sodium.bin2hex(keyPair.pk);

  Map<String, dynamic> toJson() => {'hex': hex};

  @override
  String toString() => '0x$hex';

  @override
  bool operator ==(o) => o is Address && o.hex == hex;

  @override
  int get hashCode => hex.hashCode;

  static String trim0x(String s) {
    if (s.startsWith('0x')) {
      return s.replaceFirst('0x', '');
    }

    return s;
  }
}

enum AccountType {
  user,
  library,
  actor,
}

class Account {
  final int sequence;
  final Address address;
  final Address2 address2;
  final AccountType type;
  final int balance;
  final int memorySize;
  final int memoryAllowance;

  Account({
    this.sequence,
    this.address,
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
      // TODO Remove.
      address: null,
      address2: Address2(m['address']),
      balance: m['balance'],
      type: AccountType.user,
      memorySize: m['memory_size'],
      memoryAllowance: m['allowance'],
    );
  }
}

String prefix0x(String s) => '0x$s';

sodium.KeyPair randomKeyPair() => sodium.CryptoSign.randomKeys();

Uint8List sign(Uint8List hash, Uint8List secretKey) =>
    sodium.CryptoSign.signDetached(hash, secretKey);

String langString(Lang lang) {
  switch (lang) {
    case Lang.convexLisp:
      return 'convex-lisp';
    case Lang.convexScript:
      return 'convex-scrypt';
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

Future<http.Response> getAccountRaw({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  Address address,
}) {
  var uri = Uri(
    scheme: scheme,
    host: host,
    port: port,
    path: 'api/v1/accounts/' + address.hex,
  );

  if (client == null) {
    return http.get(uri);
  }

  return client.get(uri);
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

Future<Account> getAccount({
  http.Client client,
  String scheme = 'https',
  String host = CONVEX_WORLD_HOST,
  int port = 443,
  Address address,
}) async {
  var response = await getAccountRaw(
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
    logger.d(
      '[ACCOUNT] ${response.body}',
    );
  }

  return Account.fromJson(response.body);
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
    logger.d(
      'ACCOUNT ${response.body}',
    );
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
    this.client,
  });

  Uri _uri(String path) => Uri(
        scheme: server.scheme,
        host: server.host,
        port: server.port,
        path: path,
      );

  Future<Address2> createAccount({@required AccountKey accountKey}) async {
    if (config.isDebug()) {
      logger.d(
        'Create Account with Account Key: $accountKey',
      );
    }

    var body = convert.jsonEncode({
      'public_key': accountKey.value,
    });

    final response = await client.post(
      _uri('api/v1/create-account'),
      body: body,
    );

    if (response.statusCode != 200) {
      logger.e(
        'Failed to create Account: ${response.body}',
      );

      return null;
    }

    var bodyDecoded = convert.jsonDecode(response.body);

    final address = Address2(bodyDecoded['address'] as int);

    logger.d(
      'Created Account: Address $address, Account Key $accountKey',
    );

    return address;
  }

  /// **Requests for Faucet.**
  ///
  /// Returns true if the request was successful, false otherwise.
  Future<bool> requestForFaucet({
    @required Address address,
    @required int amount,
  }) async {
    var response = await faucet(
      client: client,
      scheme: server.scheme,
      host: server.host,
      port: server.port,
      address: address.hex,
      amount: amount,
    );

    return response.statusCode == 200;
  }

  /// **Executes code on the Convex Network just to compute the result.**
  Future<Result> query({
    @required String source,
    Address caller,
    Lang lang = Lang.convexLisp,
  }) async {
    var response = await queryRaw(
      client: client,
      scheme: server.scheme,
      host: server.host,
      port: server.port,
      source: source,
      address: caller?.hex,
      lang: lang,
    );

    var bodyDecoded = convert.jsonDecode(response.body);

    if (config.isDebug()) {
      logger.d(
        '[QUERY] Source: $source, Address: $caller, Lang: $lang, Result: $bodyDecoded',
      );
    }

    var resultValue = bodyDecoded['value'];
    var resultErrorCode = bodyDecoded['error-code'];

    if (resultErrorCode != null) {
      logger.w('Query Result has an error: $resultErrorCode');
    }

    return Result(
      value: resultValue,
      errorCode: resultErrorCode,
    );
  }

  Future<Result> transact({
    @required Address caller,
    @required Uint8List callerSecretKey,
    @required String source,
    Lang lang = Lang.convexLisp,
  }) {
    var result = transact2(
      client: client,
      scheme: server.scheme,
      host: server.host,
      port: server.port,
      source: source,
      address: caller.hex,
      secretKey: callerSecretKey,
    );

    if (config.isDebug()) {
      logger.d(
        '[TRANSACT] Source: $source, Address: $caller, Lang: $lang',
      );
    }

    return result;
  }

  Future<Account> account({
    @required Address address,
  }) =>
      getAccount(
        client: client,
        scheme: server.scheme,
        host: server.host,
        port: server.port,
        address: address,
      );

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
  final Address address;
  final FungibleTokenMetadata metadata;

  FungibleToken({
    @required this.address,
    @required this.metadata,
  });

  FungibleToken.fromJson(Map<String, dynamic> json)
      : address = Address.fromJson(json['address']),
        metadata = FungibleTokenMetadata.fromJson(json['metadata']);

  Map<String, dynamic> toJson() => {
        'address': address.toJson(),
        'metadata': metadata.toJson(),
      };

  @override
  bool operator ==(o) => o is FungibleToken && o.address == address;

  @override
  int get hashCode => address.hex.hashCode;

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
  final Address address;
  final NonFungibleTokenMetadata metadata;

  NonFungibleToken({
    @required this.address,
    @required this.metadata,
  });

  NonFungibleToken.fromJson(Map<String, dynamic> json)
      : address = Address.fromJson(json['address']),
        metadata = NonFungibleTokenMetadata.fromJson(json['metadata']);

  Map<String, dynamic> toJson() => {
        'address': address.toJson(),
        'metadata': metadata.toJson(),
      };

  @override
  bool operator ==(o) => o is NonFungibleToken && o.address == address;

  @override
  int get hashCode => address.hex.hashCode;

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
    @required Address token,
    @required Address holder,
    @required Uint8List holderSecretKey,
    @required Address receiver,
    @required int amount,
  }) =>
      convexClient.transact(
        caller: holder,
        callerSecretKey: holderSecretKey,
        source: '(import convex.fungible :as fungible)'
            '(fungible/transfer 0x${token.hex}  0x${receiver.hex} $amount)',
      );

  /// **Creates (deploys) a Fungible Token on the Convex Network.**
  ///
  /// Returns the Address of the deployed Token.
  Future<Result> createToken({
    @required Address holder,
    @required Uint8List holderSecretKey,
    @required int supply,
  }) =>
      convexClient.transact(
        caller: holder,
        callerSecretKey: holderSecretKey,
        source: '(import convex.fungible :as fungible)'
            '(deploy (fungible/build-token {:supply $supply}))',
      );
}

class NonFungibleLibrary {
  final ConvexClient convexClient;

  NonFungibleLibrary({@required this.convexClient});

  Future<Result> createToken({
    @required Address caller,
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

    return convexClient.transact(
      caller: caller,
      callerSecretKey: callerSecretKey,
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
    @required Address asset,
    @required Address owner,
  }) async {
    var source = '(import convex.asset :as asset)'
        '(asset/balance 0x${asset.hex} 0x${owner.hex})';

    var result = await convexClient.query(source: source);

    if (result.errorCode != null) {
      logger.e('Failed to query balance: ${result.value}');

      return null;
    }

    return result.value;
  }

  Future<Result> transferNonFungible({
    @required Address holder,
    @required Uint8List holderSecretKey,
    @required Address receiver,
    @required Address nft,
    @required Set<int> tokens,
  }) {
    var _source = '(import convex.asset :as asset)'
        '(asset/transfer 0x${receiver.hex} [ 0x${nft.hex}, #{ ${tokens.join(",")} } ])';

    return convexClient.transact(
      caller: holder,
      callerSecretKey: holderSecretKey,
      source: _source,
    );
  }

  Future<Result> transferFungible({
    @required Address holder,
    @required Uint8List holderSecretKey,
    @required Address receiver,
    @required Address token,
    @required double amount,
  }) {
    var _source = '(import convex.asset :as asset)'
        '(asset/transfer 0x${receiver.hex} [ 0x${token.hex}, $amount ])';

    return convexClient.transact(
      caller: holder,
      callerSecretKey: holderSecretKey,
      source: _source,
    );
  }
}
