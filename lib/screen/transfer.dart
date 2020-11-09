import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_qr_bar_scanner/qr_bar_scanner_camera.dart';

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
  var _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: _formKey,
        child: _isScanning
            ? Center(
                child: SizedBox(
                  height: 1000,
                  width: 500,
                  child: QRBarScannerCamera(
                    onError: (context, error) => Text(
                      error.toString(),
                      style: TextStyle(color: Colors.red),
                    ),
                    qrCodeCallback: (code) {
                      log('QR Code $code');

                      setState(() => _isScanning = false);
                    },
                  ),
                ),
              )
            : Column(
                children: [
                  ElevatedButton(
                    child: Text('Scan QA Code'),
                    onPressed: () {
                      setState(() => _isScanning = true);
                    },
                  ),
                  TextFormField(
                    autofocus: true,
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
}
