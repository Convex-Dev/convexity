import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';

// Reference: https://tools.ietf.org/html/draft-ietf-curdle-pkix-00

final idCurve25519ObjectIdentifier = ASN1ObjectIdentifier([1, 3, 101, 100]);

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
  final privateKeySequence = ASN1Sequence()
    ..add(ASN1Integer(BigInt.from(1)))
    ..add(ASN1BitString(privateKey))
    ..add(idCurve25519ObjectIdentifier);

  final encoded = base64.encode(privateKeySequence.encodedBytes);

  return '-----BEGIN PRIVATE KEY-----\n$encoded\n-----END PRIVATE KEY-----';
}

Uint8List decodePrivateKeyPEM(String pem) {
  final encoded = pem.split('\n')[1];

  final decoded = base64.decode(encoded);

  final privateKeySequence = ASN1Parser(decoded).nextObject() as ASN1Sequence;

  final privateKeyBitString = privateKeySequence.elements[1] as ASN1BitString;

  return Uint8List.fromList(privateKeyBitString.stringValue);
}
