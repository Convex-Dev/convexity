import 'dart:developer';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:barcode_scan/barcode_scan.dart';

import '../model.dart';
import '../widget.dart';

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

  scan() async {
    var result = await BarcodeScanner.scan();

    print(result.type);
    print(result.rawContent);
    print(result.format);
    print(result.formatNote);

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
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      content: Text('OK'),
                    ),
                  );
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
