import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/crypto.dart' as crypto;

void main() {
  group('PEM encode & decode', () {
    final randomKeyPair = CryptoSign.randomKeys();

    test('Public Key', () {
      final pem = crypto.encodePublicKeyPEM(randomKeyPair.pk);
      final decodedPublicKey = crypto.decodePublicKeyPEM(pem);

      expect(decodedPublicKey, randomKeyPair.pk);

      // Encoded PEM must be the same if we encode from the decoded key.
      expect(pem, crypto.encodePublicKeyPEM(decodedPublicKey));
    });

    test('Private Key', () {
      final pem = crypto.encodePrivateKeyPEM(randomKeyPair.sk);
      final decodedSecretKey = crypto.decodePrivateKeyPEM(pem);

      expect(decodedSecretKey, randomKeyPair.sk);

      // Encoded PEM must be the same if we encode from the decoded key.
      expect(pem, crypto.encodePrivateKeyPEM(decodedSecretKey));
    });
  });
}
