import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../convex.dart' as convex;
import '../wallet.dart' as wallet;
import '../nav.dart' as nav;

class WalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convex Wallet'),
      ),
      body: WalletScreenBody(),
    );
  }
}

class WalletScreenBody extends StatefulWidget {
  WalletScreenBody({Key key}) : super(key: key);

  @override
  _WalletScreenBodyState createState() => _WalletScreenBodyState();
}

class _WalletScreenBodyState extends State<WalletScreenBody> {
  final List<sodium.KeyPair> keyPairs = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        ElevatedButton(
          child: Text('CREATE ACCOUNT'),
          onPressed: () {
            var randomKeyPair = sodium.CryptoSign.randomKeys();

            convex
                .faucet(
              address: sodium.Sodium.bin2hex(randomKeyPair.pk),
              amount: 1000000,
            )
                .then(
              (response) {
                if (response.statusCode == 200) {
                  wallet.addKeyPair(randomKeyPair);
                  wallet.select(randomKeyPair);

                  setState(() {
                    keyPairs.add(randomKeyPair);
                  });
                }
              },
            );
          },
        ),
        ...keyPairs.map(
          (keyPair) => Card(
            child: ListTile(
              leading: SvgPicture.string(
                Jdenticon.toSvg(sodium.Sodium.bin2hex(keyPair.pk)),
                fit: BoxFit.contain,
                height: 64,
                width: 64,
              ),
              title: Text(
                convex.prefix0x(sodium.Sodium.bin2hex(keyPair.pk)),
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => nav.account(
                context,
                convex.Address(
                  hex: sodium.Sodium.bin2hex(keyPair.pk),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
