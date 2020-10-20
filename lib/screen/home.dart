import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';

import '../route.dart' as route;
import '../nav.dart' as nav;
import '../wallet.dart' as wallet;
import '../convex.dart' as convex;

Widget _identicon(
  BuildContext context,
  KeyPair activeKeyPair,
  List<KeyPair> allKeyPairs,
) {
  var activeKeyPairHex =
      activeKeyPair != null ? Sodium.bin2hex(activeKeyPair.pk) : null;

  var allKeyPairsHex =
      allKeyPairs.map((_keyPair) => Sodium.bin2hex(_keyPair.pk));

  if (allKeyPairsHex.isNotEmpty) {
    return DropdownButton<String>(
      value: activeKeyPairHex,
      items: allKeyPairsHex
          .map(
            (s) => DropdownMenuItem(
              child: SvgPicture.string(
                Jdenticon.toSvg(s),
                fit: BoxFit.contain,
              ),
              value: s,
            ),
          )
          .toList(),
      onChanged: (k) {},
    );
  }

  return null;
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var identicon = _identicon(
      context,
      context.watch<AppState>().model.activeKeyPair,
      context.watch<AppState>().model.allKeyPairs,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Convexity'),
        actions: [
          if (identicon != null) identicon,
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text('Convexity'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Wallet'),
              onTap: () {
                Navigator.pop(context);

                Navigator.pushNamed(context, route.wallet);
              },
            ),
          ],
        ),
      ),
      body: HomeScreenBody(),
    );
  }
}

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: wallet.activeKeyPair(),
        builder: (
          BuildContext context,
          AsyncSnapshot<KeyPair> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.done) {
            var keyPair = snapshot.data;

            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (keyPair == null)
                    ElevatedButton(
                      child: Text('CREATE ACCOUNT'),
                      onPressed: () {
                        var randomKeyPair = CryptoSign.randomKeys();

                        convex
                            .faucet(
                          address: Sodium.bin2hex(randomKeyPair.pk),
                          amount: 1000000,
                        )
                            .then(
                          (response) {
                            if (response.statusCode == 200) {
                              context
                                  .read<AppState>()
                                  .addKeyPair(randomKeyPair);
                            }
                          },
                        );
                      },
                    )
                  else ...[
                    Text(Sodium.bin2hex(keyPair.pk)),
                    ElevatedButton(
                      child: Text('Details'),
                      onPressed: () {
                        nav.account(context,
                            convex.Address(hex: Sodium.bin2hex(keyPair.pk)));
                      },
                    )
                  ],
                ],
              ),
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      );
}
