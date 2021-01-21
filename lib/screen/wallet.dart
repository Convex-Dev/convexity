import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../convex.dart';
import '../logger.dart';
import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';
import '../crypto.dart' as crypto;

class WalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Convex Wallet'),
        actions: [
          if (appState.model.allKeyPairs.isNotEmpty)
            IdenticonDropdown(
              activeKeyPair: appState.model.activeKeyPairOrDefault(),
              allKeyPairs: appState.model.allKeyPairs,
            ),
        ],
      ),
      body: WalletScreenBody(),
    );
  }
}

class CirclePainter extends CustomPainter {
  final _paint = Paint()
    ..color = Colors.green
    ..strokeWidth = 2
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WalletScreenBody extends StatefulWidget {
  @override
  _WalletScreenBodyState createState() => _WalletScreenBodyState();
}

class _WalletScreenBodyState extends State<WalletScreenBody> {
  Widget keyPairCard(
    BuildContext context, {
    KeyPair keyPair,
    KeyPair activeKeyPair,
  }) {
    return Card(
      child: Stack(
        children: [
          Positioned(
            right: 7,
            top: 7,
            child: Opacity(
              opacity: (Address.fromKeyPair(keyPair) ==
                      Address.fromKeyPair(activeKeyPair))
                  ? 1.0
                  : 0.0,
              child: SizedBox(
                width: 13,
                height: 13,
                child: CustomPaint(
                  painter: CirclePainter(),
                ),
              ),
            ),
          ),
          Column(
            children: [
              AddressTile(
                address: Address.fromKeyPair(keyPair),
                onTap: () => nav.pushAccount(
                  context,
                  Address.fromHex(
                    Sodium.bin2hex(keyPair.pk),
                  ),
                ),
              ),
              FutureBuilder(
                future: getAccount(
                    address: Address.fromHex(Sodium.bin2hex(keyPair.pk))),
                builder: (context, snapshot) {
                  var animatedChild;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    animatedChild = SizedBox(
                      height: 63,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'loading...',
                          style: TextStyle(color: Colors.black26),
                        ),
                      ),
                    );
                  } else {
                    animatedChild = Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.data?.balance == null
                                    ? '-'
                                    : NumberFormat()
                                        .format(snapshot.data.balance),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                'Balance',
                                style: Theme.of(context).textTheme.caption,
                              )
                            ],
                          ),
                          Row(
                            children: [
                              TextButton(
                                child: Text('Make Active'),
                                onPressed: () {},
                              ),
                              TextButton(
                                child: Text('Export'),
                                onPressed: () {
                                  final appState = context.read<AppState>();

                                  print(
                                    '\n' +
                                        crypto.encodePrivateKeyPEM(
                                          appState.model.activeKeyPair.sk,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: animatedChild,
                  );
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    var activeKeyPair = appState.model.activeKeyPair;
    var allKeyPairs = appState.model.allKeyPairs;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 40,
            left: 20,
            right: 20,
          ),
          child: Text(
            'Wallet contains your own Accounts managed on this device.',
            style: Theme.of(context)
                .textTheme
                .subtitle1
                .copyWith(color: Colors.black54),
          ),
        ),
        ...(allKeyPairs
            .map(
              (_keypair) => keyPairCard(
                context,
                keyPair: _keypair,
                activeKeyPair: activeKeyPair,
              ),
            )
            .toList()),
        Gap(20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            child: Text('Create Account'),
            onPressed: () {
              _createAccount(context);
            },
          ),
        ),
      ],
    );
  }

  void _createAccount(BuildContext context) async {
    try {
      setState(() {});

      var randomKeyPair = CryptoSign.randomKeys();

      var appState = context.read<AppState>();

      var b = await appState.convexClient().requestForFaucet(
            address: Address.fromHex(Sodium.bin2hex(randomKeyPair.pk)),
            amount: 10000000,
          );

      if (b) {
        appState.addKeyPair(randomKeyPair, isPersistent: true);
        appState.addContact(
          Contact(
            name: 'Account ${appState.model.allKeyPairs.length}',
            address: Address.fromKeyPair(randomKeyPair),
          ),
        );
      } else {
        logger.e('Failed to create Account.');
      }
    } finally {
      setState(() {});
    }
  }
}
