import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';

import '../convex.dart';
import '../model.dart';

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Address address = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Account Details')),
      body: AccountScreenBody(address: address),
    );
  }
}

class AccountScreenBody extends StatefulWidget {
  final Address address;

  const AccountScreenBody({Key key, this.address}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccountScreenBodyState();
}

class _AccountScreenBodyState extends State<AccountScreenBody> {
  Future<Account> account;

  @override
  void initState() {
    super.initState();

    account = context
        .read<AppState>()
        .convexClient()
        .account(address: widget.address);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: account,
        // ignore: missing_return
        builder: (BuildContext context, AsyncSnapshot<Account> snapshot) {
          var progressIndicator = Center(child: CircularProgressIndicator());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return progressIndicator;
            case ConnectionState.waiting:
              return progressIndicator;
            case ConnectionState.active:
              return progressIndicator;
            case ConnectionState.done:
              var account = snapshot.data;

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SvgPicture.string(
                      Jdenticon.toSvg(account.address.hex, size: 88),
                      fit: BoxFit.contain,
                    ),
                    Text('Address'),
                    Text(account.address.hex),
                    Text('Type'),
                    Text(account.type.toString()),
                    Text('Balance'),
                    Text(account.balance.toString()),
                    Text('Memory Size'),
                    Text(account.memorySize.toString()),
                    Text('Memory Allowance'),
                    Text(account.memoryAllowance.toString()),
                  ],
                ),
              );

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text('Account not found.'),
                ),
              );
          }
        },
      );
}
