import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';

import '../wallet.dart' as wallet;
import '../convex.dart' as convex;
import '../main.dart';

Widget _identicon() => FutureBuilder(
      future: wallet.active(),
      builder: (
        BuildContext context,
        AsyncSnapshot<KeyPair> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.done) {
          var keyPair = snapshot.data;

          if (keyPair != null) {
            return IconButton(
              icon: SvgPicture.string(
                Jdenticon.toSvg(
                  Sodium.bin2hex(keyPair.pk),
                ),
                fit: BoxFit.contain,
              ),
              onPressed: () {},
            );
          }
        }

        return Center(child: CircularProgressIndicator());
      },
    );

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var identicon = _identicon();

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
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Wallet'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalletScreen(),
                    ));
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
        future: wallet.active(),
        builder: (
          BuildContext context,
          AsyncSnapshot<KeyPair> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.done) {
            var keyPair = snapshot.data;

            return Column(
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
                            wallet.addKeyPair(randomKeyPair);
                            wallet.select(randomKeyPair);
                          }
                        },
                      );
                    },
                  )
                else ...[
                  SvgPicture.string(
                    Jdenticon.toSvg(
                      Sodium.bin2hex(keyPair.pk),
                    ),
                    fit: BoxFit.contain,
                  ),
                  Text(Sodium.bin2hex(keyPair.pk)),
                ],
              ],
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      );
}
