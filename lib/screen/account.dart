import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../convex.dart' as convex;

class AccountDetailsScreen extends StatelessWidget {
  final convex.Address address;

  AccountDetailsScreen({
    this.address,
  }) {
    assert(address != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account Details')),
      body: AccountDetailsScreenBody(address: address),
    );
  }
}

class AccountDetailsScreenBody extends StatefulWidget {
  final convex.Address address;

  const AccountDetailsScreenBody({Key key, this.address}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _AccountDetailsScreenBodyState(address);
}

class _AccountDetailsScreenBodyState extends State<AccountDetailsScreenBody> {
  final convex.Address address;

  Future<Response> response;

  _AccountDetailsScreenBodyState(this.address);

  @override
  void initState() {
    super.initState();

    response = convex.getAccount(address: address);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: response,
        // ignore: missing_return
        builder: (BuildContext context, AsyncSnapshot<Response> snapshot) {
          var progressIndicator = Center(child: CircularProgressIndicator());

          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return progressIndicator;
            case ConnectionState.waiting:
              return progressIndicator;
            case ConnectionState.active:
              return progressIndicator;
            case ConnectionState.done:
              var account = convex.Account.fromJson(snapshot.data.body);

              return Column(
                children: [
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
              );
          }
        },
      );
}
