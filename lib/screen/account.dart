import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../convex.dart' as convex;

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final convex.Address address = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Account Details')),
      body: AccountScreenBody(address: address),
    );
  }
}

class AccountScreenBody extends StatefulWidget {
  final convex.Address address;

  const AccountScreenBody({Key key, this.address}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccountScreenBodyState(address);
}

class _AccountScreenBodyState extends State<AccountScreenBody> {
  final convex.Address address;

  Future<Response> response;

  _AccountScreenBodyState(this.address);

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
