// REFERENCE
//  https://tools.ietf.org/html/rfc8410
//  https://tools.ietf.org/html/rfc5958

import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

import 'convex.dart';

extension KeyPairJsonEncoding on KeyPair {
  Map<String, dynamic> toJson() => {
        'sk': Sodium.bin2hex(this.sk),
        'pk': Sodium.bin2hex(this.pk),
      };
}

KeyPair keyPairFromJson(Map<String, dynamic> json) => KeyPair(
      pk: Sodium.hex2bin(json['pk']),
      sk: Sodium.hex2bin(json['sk']),
    );

Map<String, dynamic> keyringToJson(Map<Address, KeyPair> keyring) =>
    keyring.map(
      (key, value) => MapEntry(
        key.toString(),
        value.toJson(),
      ),
    );

Map<Address, KeyPair> keyringFromJson(Map<String, dynamic> json) => json.map(
      (key, value) => MapEntry(
        Address.fromStr(key),
        keyPairFromJson(value),
      ),
    );

final idCurve25519ObjectIdentifier = ASN1ObjectIdentifier([1, 3, 101, 112]);

String encodePublicKeyPEM(Uint8List publicKey) {
  final algorithmIdentifier = ASN1Sequence()..add(idCurve25519ObjectIdentifier);

  final subjectPublicKeyInfo = ASN1Sequence()
    ..add(algorithmIdentifier)
    ..add(ASN1BitString(publicKey));

  final encoded = base64.encode(subjectPublicKeyInfo.encodedBytes);

  return '-----BEGIN PUBLIC KEY-----\n$encoded\n-----END PUBLIC KEY-----';
}

Uint8List decodePublicKeyPEM(String pem) {
  final encoded = pem.split('\n')[1];

  final decoded = base64.decode(encoded);

  final subjectPublicKeyInfo = ASN1Parser(decoded).nextObject() as ASN1Sequence;

  final publicKeyBitString =
      subjectPublicKeyInfo.elements.last as ASN1BitString;

  return Uint8List.fromList(publicKeyBitString.stringValue);
}

String encodePrivateKeyPEM(Uint8List privateKey) {
  final version = ASN1Integer(BigInt.from(1));

  final algorithm = ASN1Sequence();
  algorithm.add(idCurve25519ObjectIdentifier);

  final privateKeyOctetString = ASN1OctetString(
    ASN1OctetString(privateKey.sublist(0, 32)).encodedBytes,
  );

  final publicKeyBitString = ASN1BitString(privateKey.sublist(32, 64));

  final curdleAttribute = ASN1Sequence()
    ..add(
      ASN1ObjectIdentifier([1, 2, 840, 113549, 1, 9, 9, 20]),
    )
    ..add(
      ASN1Set()
        ..add(
          ASN1UTF8String("Curdle Chairs"),
        ),
    );

  final attributes = ASN1Set()
    ..add(
      curdleAttribute,
    );

  final oneAsymmetricKey = ASN1Sequence()
    ..add(version)
    ..add(algorithm)
    ..add(privateKeyOctetString)
    // Attrbiutes
    ..add(attributes)
    // Public Key
    ..add(publicKeyBitString);

  final encoded = base64.encode(oneAsymmetricKey.encodedBytes);

  return '-----BEGIN PRIVATE KEY-----\n$encoded\n-----END PRIVATE KEY-----';
}

Uint8List decodePrivateKeyPEM(String pem) {
  final encoded = pem.split('\n')[1];

  final decoded = base64.decode(encoded);

  final privateKeySequence = ASN1Parser(decoded).nextObject() as ASN1Sequence;

  final privateKeyOctetString =
      privateKeySequence.elements[2] as ASN1OctetString;

  return privateKeyOctetString.valueBytes();
}
