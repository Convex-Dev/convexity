import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:meta/meta.dart';

import 'config.dart' as config;
import 'logger.dart';

final convexWorldUri = Uri.parse('https://convex.world');

enum Lang {
  convexLisp,
  convexScript,
}

String langString(Lang lang) {
  switch (lang) {
    case Lang.convexLisp:
      return 'convexLisp';
    case Lang.convexScript:
      return 'convexScrypt';
  }
}

@immutable
class Address {
  final int? value;

  Address(this.value);

  Address.fromStr(String s) : value = int.parse(s.replaceFirst('#', ''));

  Address.fromJson(Map<String, dynamic> m) : value = (m['value'] as int?);

  @override
  String toString() => '#$value';

  @override
  bool operator ==(o) => o is Address && o.value == value;

  @override
  int get hashCode => value.hashCode;

  Map<String, dynamic> toJson() => {'value': value};
}

@immutable
class AccountKey {
  // String of HEX characters.
  final String value;

  AccountKey(this.value);

  AccountKey.fromBin(Uint8List bin) : value = sodium.Sodium.bin2hex(bin);

  Uint8List toBin() => sodium.Sodium.hex2bin(value);

  @override
  String toString() => '0x$value';

  @override
  bool operator ==(o) => o is AccountKey && o.value == value;

  @override
  int get hashCode => value.hashCode;
}

enum AccountType {
  user,
  library,
  actor,
}

AccountType? accountType(String s) {
  switch (s.toLowerCase()) {
    case 'user':
      return AccountType.user;
    case 'library':
      return AccountType.library;
    case 'actor':
      return AccountType.actor;
  }

  return null;
}

@immutable
class Credentials {
  final Address? address;
  final AccountKey? accountKey;
  final Uint8List? secretKey;

  Credentials({
    this.address,
    this.accountKey,
    this.secretKey,
  });
}

@immutable
class Account {
  final int? sequence;
  final Address? address;
  final AccountType? type;
  final int? balance;
  final int? memorySize;
  final int? memoryAllowance;

  Account({
    this.sequence,
    this.address,
    this.balance,
    this.type,
    this.memorySize,
    this.memoryAllowance,
  });

  static Account fromJson(String json) {
    var m = convert.jsonDecode(json);

    return Account(
      sequence: m['sequence'],
      address: Address(m['address']),
      balance: m['balance'],
      type: accountType(m['type']),
      memorySize: m['memorySize'],
      memoryAllowance: m['allowance'],
    );
  }
}

Uint8List sign(Uint8List hash, Uint8List secretKey) =>
    sodium.CryptoSign.signDetached(hash, secretKey);

@immutable
class Result {
  final dynamic value;
  final String? errorCode;

  Result({
    this.value,
    this.errorCode,
  });

  @override
  String toString() {
    return 'Result[errorCode: $errorCode, value: $value]';
  }

  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        'value': value,
      };
}

class ConvexClient {
  final Uri? server;
  final http.Client client;

  // Credentials can change over time.
  Credentials? credentials;

  ConvexClient({
    required this.server,
    required this.client,
    this.credentials,
  });

  void setCredentials(Credentials credentials) =>
      this.credentials = credentials;

  Uri _uri(String path) => Uri(
        scheme: server!.scheme,
        host: server!.host,
        port: server!.port,
        path: path,
      );

  Future<http.Response> prepareTransaction({
    required String source,
    int? sequence,
    Lang lang = Lang.convexLisp,
  }) {
    if (credentials == null || credentials!.address == null)
      throw Exception('Missing credentials.');

    final uri = _uri('api/v1/transaction/prepare');

    Map<String, dynamic> body = {
      'source': source,
      'address': credentials!.address!.value,
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

  Future<http.Response> submitTransaction({
    required String hash,
    required String sig,
  }) {
    if (credentials == null ||
        credentials!.address == null ||
        credentials!.accountKey == null)
      throw Exception('Missing credentials.');

    final uri = _uri('api/v1/transaction/submit');

    Map<String, dynamic> body = {
      'address': credentials!.address!.value,
      'accountKey': credentials!.accountKey!.value,
      'hash': hash,
      'sig': sig,
    };

    final bodyEncoded = convert.jsonEncode(body);

    if (config.isDebug()) {
      logger.d(body);
    }

    return client.post(uri, body: bodyEncoded);
  }

  Future<Result> transact({
    required String source,
    int? sequence,
    Lang lang = Lang.convexLisp,
  }) async {
    final prepared = await prepareTransaction(
      source: source,
      sequence: sequence,
      lang: lang,
    );

    final preparedBody = convert.jsonDecode(prepared.body);

    if (prepared.statusCode != 200) {
      throw Exception(preparedBody['errorCode']);
    }

    final hashHex = preparedBody['hash'];
    final hashBin = sodium.Sodium.hex2bin(hashHex);

    final sigBin = sign(hashBin, credentials!.secretKey!);
    final sigHex = sodium.Sodium.bin2hex(sigBin);

    final submitResponse = await submitTransaction(
      hash: hashHex,
      sig: sigHex,
    );

    final submitBody = convert.jsonDecode(submitResponse.body);

    if (submitResponse.statusCode != 200) {
      throw Exception(submitBody['errorCode']);
    }

    final result = Result(
      value: submitBody['value'],
      errorCode: submitBody['errorCode'],
    );

    if (config.isDebug()) {
      logger.d(result.toJson());
    }

    return result;
  }

  Future<Address?> createAccount([AccountKey? accountKey]) async {
    if (accountKey == null && credentials?.accountKey == null)
      throw Exception('Missing AccountKey.');

    final body = convert.jsonEncode({
      'accountKey': accountKey?.value ?? credentials!.accountKey!.value,
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

    final address = Address(bodyDecoded['address'] as int?);

    return address;
  }

  Future<http.Response> faucet({
    Address? address,
    required int amount,
  }) async {
    final uri = _uri('api/v1/faucet');

    var body = convert.jsonEncode({
      'address': address != null ? address.value : credentials!.address!.value,
      'amount': amount,
    });

    if (config.isDebug()) {
      logger.d(body);
    }

    return client.post(uri, body: body);
  }

  /// **Executes code on the Convex Network just to compute the result.**
  Future<Result> query({
    required String source,
    Lang lang = Lang.convexLisp,
  }) async {
    final uri = _uri('api/v1/query');

    var body = convert.jsonEncode({
      'source': source,
      'address': credentials!.address!.value,
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

  Future<Account> accountDetails([Address? address]) async {
    if (address == null && credentials?.address == null)
      throw Exception('Missing credentials.');

    final uri = _uri(
      'api/v1/accounts/${address != null ? address.value : credentials!.address!.value}',
    );

    final response = await client.get(uri);

    if (config.isDebug()) {
      logger.d(response.body);
    }

    return Account.fromJson(response.body);
  }

  Future<int?> balance([Address? address]) async {
    if (address == null && credentials?.address == null)
      throw Exception('Missing credentials.');

    final uri = _uri(
      'api/v1/accounts/${address != null ? address.value : credentials!.address!.value}',
    );

    final response = await client.get(uri);

    if (config.isDebug()) {
      logger.d(response.body);
    }

    final a = Account.fromJson(response.body);

    return a.balance;
  }

  ConvexClient copyWith({Credentials? credentials}) => ConvexClient(
        server: this.server,
        client: this.client,
        credentials: credentials ?? this.credentials,
      );
}

abstract class Asset {}

@immutable
class FungibleTokenMetadata {
  final String? name;
  final String? description;
  final String? symbol;
  final String? currencySymbol;
  final int? decimals;

  FungibleTokenMetadata({
    required this.name,
    required this.description,
    required this.symbol,
    required this.currencySymbol,
    required this.decimals,
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
    required this.address,
    required this.metadata,
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
  int get hashCode => address.hashCode;

  @override
  String toString() {
    return toJson().toString();
  }
}

@immutable
class NonFungibleTokenMetadata implements Asset {
  final String? name;
  final String? description;

  NonFungibleTokenMetadata({
    required this.name,
    required this.description,
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
    required this.address,
    required this.metadata,
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
  final int? id;
  final Map<String, dynamic>? data;
  final NonFungibleItemPolicy? policy;

  NonFungibleItem({
    this.id,
    this.data,
    this.policy,
  });
}

class FungibleLibrary {
  final ConvexClient convexClient;

  FungibleLibrary({required this.convexClient});

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
    required Address token,
    required Address? holder,
    required AccountKey? holderAccountKey,
    required Uint8List holderSecretKey,
    required Address? receiver,
    required int? amount,
  }) =>
      convexClient.transact(
        source: '(import convex.fungible :as fungible)'
            '(fungible/transfer $token $receiver $amount)',
      );

  /// **Creates (deploys) a Fungible Token on the Convex Network.**
  ///
  /// Returns the Address of the deployed Token.
  Future<Result> createToken({
    required int supply,
  }) =>
      convexClient.transact(
        source: '(import convex.fungible :as fungible)'
            '(deploy (fungible/build-token {:supply $supply}))',
      );

  /// **Creates (deploys) a Fungible Token on the Convex Network.**
  ///
  /// Returns the Address of the deployed Token.
  Future<Address> createToken2({
    required int supply,
  }) async {
    final result = await convexClient.transact(
      source: '(import convex.fungible :as fungible)'
          '(deploy (fungible/build-token {:supply $supply}))',
    );

    if (result.errorCode != null)
      throw Exception('${result.errorCode}: ${result.value}');

    return Address(result.value);
  }
}

class NonFungibleLibrary {
  final ConvexClient convexClient;

  NonFungibleLibrary({required this.convexClient});

  Future<Result> createToken({
    required Address caller,
    required AccountKey callerAccountKey,
    required Uint8List callerSecretKey,
    Map<String, dynamic>? attributes,
  }) {
    final _attributes = attributes ?? {};

    final _name = _attributes['name'] as String? ?? 'No name';
    final _uri = _attributes['uri'] as String?;

    final _data = '{'
        ':name "$_name",'
        ':uri "$_uri",'
        ':extra {}'
        '}';

    var _source = '(import convex.nft-tokens :as nft)'
        '(deploy (nft/create-token $_data nil) )';

    return convexClient.transact(
      source: _source,
    );
  }
}

class AssetLibrary {
  final ConvexClient convexClient;

  AssetLibrary({required this.convexClient});

  /// Balance is based on the type of Asset.
  /// It returns a number for Fungible Tokens,
  /// but a set of numbers (IDs) for Non-Fungible Tokens.
  Future<dynamic> balance({
    required Address? asset,
    Address? owner,
  }) async {
    final source = '(import convex.asset :as asset)'
        '(asset/balance $asset ${owner != null ? owner : convexClient.credentials!.address})';

    final result = await convexClient.query(source: source);

    if (result.errorCode != null) {
      logger.e('Failed to query balance: ${result.value}');

      return null;
    }

    return result.value;
  }

  Future<Result> transferNonFungible({
    required Address? holder,
    required Uint8List holderSecretKey,
    required AccountKey? holderAccountKey,
    required Address? receiver,
    required Address nft,
    required Set<int?> tokens,
  }) {
    var _source = '(import convex.asset :as asset)'
        '(asset/transfer $receiver [ $nft, #{ ${tokens.join(",")} } ])';

    return convexClient.transact(
      source: _source,
    );
  }

  Future<Result> transferFungible({
    required Address holder,
    required AccountKey holderAccountKey,
    required Uint8List holderSecretKey,
    required Address receiver,
    required Address token,
    required double amount,
  }) {
    var _source = '(import convex.asset :as asset)'
        '(asset/transfer $receiver [ $token, $amount ])';

    return convexClient.transact(
      source: _source,
    );
  }
}
