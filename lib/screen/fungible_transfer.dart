import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

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
      _FungibleTransferScreenBodyState();
}

class _FungibleTransferScreenBodyState
    extends State<FungibleTransferScreenBody> {
  var inputOption = AddressInputOption.scan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      inputOption = AddressInputOption.scan;
                    });
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    child: Icon(
                      Icons.qr_code,
                      size: 60,
                      color: inputOption == AddressInputOption.scan
                          ? Colors.black
                          : Colors.black12,
                    ),
                  ),
                ),
              ),
              Gap(20),
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      inputOption = AddressInputOption.textField;
                    });
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    child: Center(
                      child: Icon(
                        Icons.text_fields,
                        size: 60,
                        color: inputOption == AddressInputOption.textField
                            ? Colors.black
                            : Colors.black12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
