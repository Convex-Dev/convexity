import 'dart:convert';

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/crypto.dart' as crypto;

void main() {
  group('PEM encode & decode', () {
    final randomKeyPair = CryptoSign.randomKeys();

    test('Public Key', () {
      final pem = crypto.encodePublicKeyPEM(randomKeyPair.pk);

      print(pem);

      final decodedPublicKey = crypto.decodePublicKeyPEM(pem);

      expect(decodedPublicKey, randomKeyPair.pk);

      // Encoded PEM must be the same if we encode from the decoded key.
      expect(pem, crypto.encodePublicKeyPEM(decodedPublicKey));
    });

    test('Private Key', () {
      final pem = crypto.encodePrivateKeyPEM(randomKeyPair.sk);

      print(
        'PUBLIC KEY\n' +
            Sodium.bin2hex(randomKeyPair.pk) +
            '\n\n' +
            'PRIVATE KEY\n' +
            Sodium.bin2hex(randomKeyPair.sk) +
            '\n\n' +
            pem,
      );

      // final decodedSecretKey = crypto.decodePrivateKeyPEM(pem);
      //
      // expect(decodedSecretKey, randomKeyPair.sk);
      //
      // // Encoded PEM must be the same if we encode from the decoded key.
      // expect(pem, crypto.encodePrivateKeyPEM(decodedSecretKey));
    });
  });
}
