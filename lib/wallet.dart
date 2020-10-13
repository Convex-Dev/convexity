import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:shared_preferences/shared_preferences.dart';

void addKeyPair(KeyPair keyPair) {
  SharedPreferences.getInstance().then((preferences) {
    var k = 'wallet';

    List<String> wallet = preferences.getStringList(k) ?? [];

    wallet.add(
      '${Sodium.bin2hex(keyPair.pk)};${Sodium.bin2hex(keyPair.sk)}',
    );

    preferences.setStringList(k, wallet);
  });
}

Future<List<KeyPair>> read() async {
  var preferences = await SharedPreferences.getInstance();

  var k = 'wallet';

  List<String> wallet = preferences.getStringList(k) ?? [];

  return wallet.map((s) {
    var keys = s.split(';');

    return KeyPair(
      pk: Sodium.hex2bin(keys[0]),
      sk: Sodium.hex2bin(keys[1]),
    );
  }).toList();
}
