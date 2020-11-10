import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:barcode_scan/barcode_scan.dart';

import '../model.dart';
import '../widget.dart';
import '../convex.dart' as convex;

class TransferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transfer')),
      body: TransferScreenBody(),
    );
  }
}

class TransferScreenBody extends StatefulWidget {
  @override
  _TransferScreenBodyState createState() => _TransferScreenBodyState();
}

class _TransferScreenBodyState extends State<TransferScreenBody> {
  var _formKey = GlobalKey<FormState>();
  var _targetController = TextEditingController();
  var _amountController = TextEditingController();

  scan() async {
    var result = await BarcodeScanner.scan();

    setState(() {
      _targetController.text = result.rawContent;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            IdenticonDropdown(
              activeKeyPair: appState.model.activeKeyPair,
              allKeyPairs: appState.model.allKeyPairs,
            ),
            ElevatedButton(
              child: Text('Scan QA Code'),
              onPressed: () {
                scan();
              },
            ),
            TextFormField(
              autofocus: false,
              controller: _targetController,
              decoration: InputDecoration(
                labelText: 'Destination',
                hintText: 'Address',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the address';
                }

                return null;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              controller: _amountController,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the amount';
                }

                return null;
              },
            ),
            ElevatedButton(
              child: Text('Transfer'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  convex
                      .transact(
                    address: appState.model.activeAddress,
                    source:
                        '(transfer "${appState.model.activeAddress}" ${_amountController.text})',
                    secretKey: appState.model.activeKeyPair.sk,
                  )
                      .then((value) {
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${value.value}'),
                      ),
                    );
                  });
                }
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();

    super.dispose();
  }
}
