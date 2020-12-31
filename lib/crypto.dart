import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';

String encodePublicKeyPEM(Uint8List pk) {
  final algorithm = ASN1ObjectIdentifier([1, 3, 101, 100]);

  final algorithmIdentifier = ASN1Sequence()..add(algorithm);

  final subjectPublicKeyInfo = ASN1Sequence()
    ..add(algorithmIdentifier)
    ..add(ASN1BitString(pk));

  final encoded = base64.encode(subjectPublicKeyInfo.encodedBytes);

  return '-----BEGIN PUBLIC KEY-----\n$encoded\n-----END PUBLIC KEY-----';
}
