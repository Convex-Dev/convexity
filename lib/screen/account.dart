import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  Widget _addressInfo(String account) {
    return StatelessWidgetBuilder(
      (context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    Gap(4),
                    SelectableText(
                      account,
                      showCursor: false,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
              ),
              QrImage(
                data: widget.address.hex,
                version: QrVersions.auto,
                size: 80,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    @required String label,
    @required String value,
  }) {
    return StatelessWidgetBuilder(
      (context) => Card(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Text(
                      label,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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

            if (account == null) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text('Account not found.'),
                ),
              );
            }

            final fields = [
              _addressInfo(account.address.toString()),
              _field(
                label: "Type",
                value: account.type.toString(),
              ),
              _field(
                label: "Balance",
                value: account.balance.toString(),
              ),
              _field(
                label: "Memory Size",
                value: account.memorySize.toString(),
              ),
              _field(
                label: "Memory Allowance",
                value: account.memoryAllowance.toString(),
              ),
            ];

            final animated = fields
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
                  children: animated,
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
}
