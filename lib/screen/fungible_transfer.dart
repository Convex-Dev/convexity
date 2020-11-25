import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../model.dart';

class FungibleTransferScreen extends StatelessWidget {
  final FungibleToken token;

  const FungibleTransferScreen({Key key, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Token can be passed directly to the constructor,
    // or via the Navigator arguments.
    var _token =
        token ?? ModalRoute.of(context).settings.arguments as FungibleToken;

    return Scaffold(
      appBar: AppBar(title: Text('Transfer ${_token.metadata.symbol}')),
      body: FungibleTransferScreenBody(token: _token),
    );
  }
}

class FungibleTransferScreenBody extends StatefulWidget {
  final FungibleToken token;

  const FungibleTransferScreenBody({Key key, this.token}) : super(key: key);

  @override
  _FungibleTransferScreenBodyState createState() =>
      _FungibleTransferScreenBodyState(token: token);
}

class _FungibleTransferScreenBodyState
    extends State<FungibleTransferScreenBody> {
  final FungibleToken token;

  _FungibleTransferScreenBodyState({this.token});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('...'),
    );
  }
}
