import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

import '../model.dart';
import '../format.dart';

class FungibleTransferScreen extends StatelessWidget {
  final FungibleToken token;

  const FungibleTransferScreen({Key key, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var arguments = ModalRoute.of(context).settings.arguments as List;

    // Token can be passed directly to the constructor,
    // or via the Navigator arguments.
    var _token = token ?? arguments.first as FungibleToken;
    var _balance = arguments.last as Future<int>;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Transfer ${_token.metadata.symbol}',
              ),
              FutureBuilder(
                future: _balance,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  var v = formatFungible(
                    metadata: _token.metadata,
                    balance: snapshot.data as int,
                  );

                  return Text(
                    'Balance $v',
                    style: TextStyle(fontSize: 14),
                  );
                },
              )
            ],
          ),
        ),
      ),
      body: FungibleTransferScreenBody(token: _token),
    );
  }
}

class FungibleTransferScreenBody extends StatefulWidget {
  final FungibleToken token;

  const FungibleTransferScreenBody({Key key, this.token}) : super(key: key);

  @override
  _FungibleTransferScreenBodyState createState() =>
      _FungibleTransferScreenBodyState();
}

class _FungibleTransferScreenBodyState
    extends State<FungibleTransferScreenBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Amount',
            ),
          ),
          Gap(30),
          Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Destination Address',
                ),
              ),
              Gap(20),
              SizedBox(
                height: 60,
                width: 100,
                child: ElevatedButton(
                  child: Text('SEND'),
                  onPressed: () {},
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
