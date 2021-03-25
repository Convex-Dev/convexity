// REQUIREMENTS
// 'libsodium' must be installed on your lachine to be able to run these tests.
// On macOS: brew install libsodium

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/convex.dart';
import '../lib/crypto.dart' as crypto;

void main() {
  group('JSON encoding & decoding', () {
    final generatedKeyPair = CryptoSign.randomKeys();

    test('Keypair to JSON', () {
      expect(
        generatedKeyPair.toJson(),
        {
          'sk': Sodium.bin2hex(generatedKeyPair.sk),
          'pk': Sodium.bin2hex(generatedKeyPair.pk),
        },
      );
    });

    test('Keyring to JSON', () {
      expect(
        crypto.keyringToJson({Address(1): generatedKeyPair}),
        {
          '#1': {
            'sk': Sodium.bin2hex(generatedKeyPair.sk),
            'pk': Sodium.bin2hex(generatedKeyPair.pk),
          }
        },
      );
    });

    test('Keyring from JSON', () {
      final keyring = crypto.keyringFromJson(
        crypto.keyringToJson({
          Address(1): generatedKeyPair,
        }),
      );

      expect(
        true,
        keyring.containsKey(Address(1)),
      );

      expect(
        true,
        Sodium.bin2hex(keyring[Address(1)]!.sk) ==
                Sodium.bin2hex(generatedKeyPair.sk) &&
            Sodium.bin2hex(keyring[Address(1)]!.pk) ==
                Sodium.bin2hex(generatedKeyPair.pk),
      );
    });
  });

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

      print(pem);

      // final decodedSecretKey = crypto.decodePrivateKeyPEM(pem);
      //
      // expect(decodedSecretKey, randomKeyPair.sk);
      //
      // // Encoded PEM must be the same if we encode from the decoded key.
      // expect(pem, crypto.encodePrivateKeyPEM(decodedSecretKey));
    });
  });
}
