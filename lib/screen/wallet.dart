import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

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
  var isCreatingAccount = false;

  Widget keyPairCard(
    BuildContext context, {
    KeyPair keyPair,
    KeyPair activeKeyPair,
  }) {
    final isActive =
        Address.fromKeyPair(keyPair) == Address.fromKeyPair(activeKeyPair);

    return Card(
      child: Stack(
        children: [
          Positioned(
            right: 7,
            top: 7,
            child: Opacity(
              opacity: isActive ? 1.0 : 0.0,
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
              Row(
                children: [
                  TextButton(
                    child: Text(
                      'MAKE ACTIVE',
                      style: TextStyle(
                        color: isActive ? Colors.grey : Colors.blue,
                      ),
                    ),
                    onPressed: () {
                      context.read<AppState>().setActiveKeyPair(
                            keyPair,
                            isPersistent: true,
                          );
                    },
                  ),
                  TextButton(
                    child: Text('EXPORT'),
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: Icon(
                            Icons.delete,
                            color: isActive ? Colors.grey : Colors.blue,
                          ),
                          label: Text(
                            'REMOVE',
                            style: TextStyle(
                              color: isActive ? Colors.grey : Colors.blue,
                            ),
                          ),
                          onPressed: () {
                            final appState = context.read<AppState>();

                            if (Address.fromKeyPair(keyPair) ==
                                appState.model.activeAddress) {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return SafeArea(
                                    child: Container(
                                      height: 300,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.info,
                                            size: 80,
                                            color: Colors.black12,
                                          ),
                                          Gap(20),
                                          Text(
                                            "You can't remove your active Account.",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1,
                                          ),
                                          Gap(40),
                                          ElevatedButton(
                                            child: const Text('Okay'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                              return;
                            }

                            _remove(context, keyPair: keyPair);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

    final widgets = [
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
    ];

    final animated = widgets
        .asMap()
        .entries
        .map(
          (e) => AnimationConfiguration.staggeredList(
            position: e.key,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: e.value,
              ),
            ),
          ),
        )
        .toList();

    return Column(
      children: [
        Expanded(
          child: AnimationLimiter(
            child: ListView(
              children: animated,
            ),
          ),
        ),
        Gap(20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            child: isCreatingAccount
                ? SizedBox(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      strokeWidth: 2,
                    ),
                    width: 20,
                    height: 20,
                  )
                : Text('Create Account'),
            onPressed: () {
              if (isCreatingAccount) {
                return;
              }

              _createAccount(context);
            },
          ),
        ),
      ],
    );
  }

  void _createAccount(BuildContext context) async {
    try {
      setState(() {
        isCreatingAccount = true;
      });

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
          isPersistent: true,
        );
      } else {
        logger.e('Failed to create Account.');
      }
    } finally {
      setState(() {
        isCreatingAccount = false;
      });
    }
  }

  void _remove(BuildContext context, {KeyPair keyPair}) async {
    var confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) => _Remove(keyPair: keyPair),
    );

    if (confirmation == true) {
      final appState = context.read<AppState>();

      appState.removeKeyPair(keyPair, isPersistent: true);
    }
  }
}

class _Remove extends StatefulWidget {
  final KeyPair keyPair;

  const _Remove({Key key, this.keyPair}) : super(key: key);

  @override
  _RemoveState createState() => _RemoveState();
}

class _RemoveState extends State<_Remove> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final address = Address.fromKeyPair(widget.keyPair);
    final contact = appState.findContact(address);

    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Remove ${contact?.name ?? address.toString()}?',
                style: Theme.of(context).textTheme.headline6,
              ),
              Gap(20),
              aidenticon(
                Address.fromKeyPair(widget.keyPair),
                width: 80,
                height: 80,
              ),
              Gap(5),
              Text(
                Address.fromKeyPair(widget.keyPair).toString(),
                style: Theme.of(context).textTheme.caption,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlineButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  Gap(10),
                  ElevatedButton(
                    child: const Text('Confirm'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
