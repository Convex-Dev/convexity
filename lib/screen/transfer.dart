import 'dart:typed_data';

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
  var isTransfering = false;

  var formKey = GlobalKey<FormState>();

  var targetController = TextEditingController();
  var amountController = TextEditingController();

  void scan() async {
    var result = await BarcodeScanner.scan();

    setState(() {
      targetController.text = result.rawContent;
    });
  }

  void transfer({
    BuildContext context,
    Uint8List signerSecretKey,
    String targetAddress,
    int amount,
  }) async {
    var result = await convex.transact(
      address: targetAddress,
      source: '(transfer "$targetAddress" $amount)',
      secretKey: signerSecretKey,
    );

    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.value}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: formKey,
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
              controller: targetController,
              decoration: InputDecoration(
                labelText: 'Destination',
                hintText: 'Address',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the address.';
                }

                return null;
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              controller: amountController,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the amount.';
                }

                if (int.tryParse(value) == null) {
                  return 'Please enter the amount as number.';
                }

                return null;
              },
            ),
            ElevatedButton(
              child: Text('Transfer'),
              onPressed: () {
                if (formKey.currentState.validate()) {
                  transfer(
                    context: context,
                    signerSecretKey: appState.model.activeKeyPair.sk,
                    targetAddress: appState.model.activeAddress,
                    amount: int.parse(amountController.text),
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
    targetController.dispose();
    amountController.dispose();

    super.dispose();
  }
}
