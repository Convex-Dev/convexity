import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _walletPreferencesKey = 'wallet';

void addKeyPair(KeyPair keyPair) {
  SharedPreferences.getInstance().then((preferences) {
    List<String> wallet =
        preferences.getStringList(_walletPreferencesKey) ?? [];

    // Wallet is encoded as a list of public key ';' private key string.
    wallet.add(
      '${Sodium.bin2hex(keyPair.pk)};${Sodium.bin2hex(keyPair.sk)}',
    );

    preferences.setStringList(_walletPreferencesKey, wallet);
  });
}

Future<List<KeyPair>> read() async {
  var preferences = await SharedPreferences.getInstance();

  List<String> wallet = preferences.getStringList(_walletPreferencesKey) ?? [];

  return wallet.map((s) {
    var keys = s.split(';');

    return KeyPair(
      pk: Sodium.hex2bin(keys[0]),
      sk: Sodium.hex2bin(keys[1]),
    );
  }).toList();
}
