import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../model.dart';
import '../convex.dart' as convex;
import '../nav.dart' as nav;
import '../widget.dart';
import '../crypto.dart' as crypto;

void _createAccount(BuildContext context) {
  var randomKeyPair = CryptoSign.randomKeys();

  convex
      .faucet(
    address: Sodium.bin2hex(randomKeyPair.pk),
    amount: 1000000,
  )
      .then(
    (response) {
      if (response.statusCode == 200) {
        var state = context.read<AppState>();

        state.addKeyPair(randomKeyPair, isPersistent: true);
        state.setActiveKeyPair(randomKeyPair, isPersistent: true);
      }
    },
  );
}

class CreateAccountButton extends StatelessWidget {
  const CreateAccountButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        _createAccount(context);
      },
    );
  }
}

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
      floatingActionButton: CreateAccountButton(),
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

class WalletScreenBody extends StatelessWidget {
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
              opacity: (convex.Address.fromKeyPair(keyPair) ==
                      convex.Address.fromKeyPair(activeKeyPair))
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
              ListTile(
                leading: SvgPicture.string(
                  Jdenticon.toSvg(Sodium.bin2hex(keyPair.pk)),
                  fit: BoxFit.contain,
                  height: 64,
                  width: 64,
                ),
                title: Text(
                  convex.prefix0x(Sodium.bin2hex(keyPair.pk)),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('Address'),
                onTap: () => nav.pushAccount(
                  context,
                  convex.Address.fromHex(
                    Sodium.bin2hex(keyPair.pk),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: convex.prefix0x(Sodium.bin2hex(keyPair.pk)),
                      ),
                    );
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Copied ${convex.prefix0x(Sodium.bin2hex(keyPair.pk))}'),
                      ),
                    );
                  },
                ),
              ),
              FutureBuilder(
                future: convex.getAccount(
                    address:
                        convex.Address.fromHex(Sodium.bin2hex(keyPair.pk))),
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

    if (allKeyPairs.isEmpty) {
      return Center(
        child: RaisedButton(
          child: Text('Create Account'),
          onPressed: () {
            _createAccount(context);
          },
        ),
      );
    }

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
      ],
    );
  }
}
