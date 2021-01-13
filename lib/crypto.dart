// Reference: https://tools.ietf.org/html/rfc8410

import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';

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
  final version = ASN1Integer(BigInt.from(0));

  final algorithm = ASN1Sequence();
  algorithm.add(idCurve25519ObjectIdentifier);

  final privateKeyInfo = ASN1Sequence()
    ..add(version)
    ..add(algorithm)
    ..add(ASN1OctetString(privateKey));

  final encoded = base64.encode(privateKeyInfo.encodedBytes);

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
