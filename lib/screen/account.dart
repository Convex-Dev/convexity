import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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

              final children = [
                // -- Address
                ListTile(
                  title: SelectableText(
                    account.address.toString(),
                  ),
                  subtitle: Text('Address'),
                ),

                // -- Type
                ListTile(
                  title: Text(account.type.toString()),
                  subtitle: Text('Type'),
                ),

                // -- Balance
                ListTile(
                  title: Text(account.balance.toString()),
                  subtitle: Text('Balance'),
                ),

                // -- Memory Size
                ListTile(
                  title: Text(account.memorySize.toString()),
                  subtitle: Text('Memory Size'),
                ),

                // -- Memory Allowance
                ListTile(
                  title: Text(account.memoryAllowance.toString()),
                  subtitle: Text('Memory Allowance'),
                ),
              ]
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

              return Padding(
                padding: const EdgeInsets.all(12),
                child: AnimationLimiter(
                  child: ListView(
                    children: children,
                  ),
                ),
              );
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text('Account not found.'),
            ),
          );
        },
      );
}
