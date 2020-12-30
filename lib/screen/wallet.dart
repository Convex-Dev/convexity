import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:convex_wallet/convex.dart' as convex;
import 'package:convex_wallet/nav.dart' as nav;
import 'package:convex_wallet/widget.dart';

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

class WalletScreenBody extends StatelessWidget {
  Widget keyPairCard(BuildContext context, KeyPair keyPair) {
    final appState = context.watch<AppState>();

    return Card(
      child: Column(
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
            onTap: () => nav.pushAccount(
              context,
              convex.Address(
                hex: Sodium.bin2hex(keyPair.pk),
              ),
            ),
          ),
          FutureBuilder(
              future: appState
                  .convexClient()
                  .account(address: appState.model.activeAddress),
              builder: (context, snapshot) {
                var balance;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  final progress = Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                  balance = progress;
                } else {
                  balance = Text(
                    snapshot.data?.balance == null
                        ? '-'
                        : NumberFormat().format(snapshot.data.balance),
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: balance,
                        subtitle: Text('Balance'),
                      ),
                    ),
                  ],
                );
              })
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var allKeyPairs = context.watch<AppState>().model.allKeyPairs;

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
      padding: const EdgeInsets.all(8),
      children: allKeyPairs
          .map((_keypair) => keyPairCard(context, _keypair))
          .toList(),
    );
  }
}
