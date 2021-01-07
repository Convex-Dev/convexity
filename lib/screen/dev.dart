import 'dart:developer';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../nav.dart' as nav;
import '../model.dart';

class DevScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dev')),
      body: DevScreenBody(),
    );
  }
}

class DevScreenBody extends StatefulWidget {
  @override
  _DevScreenBodyState createState() => _DevScreenBodyState();
}

class _DevScreenBodyState extends State<DevScreenBody> {
  var formKey = GlobalKey<FormState>();

  var convexityController = TextEditingController(
    text: '0xc797058Ce310cDD0679819715C097D6257Ebf3E2aB531926d8F4D1c2BE87C5ae',
  );

  void scan() async {
    var result = await BarcodeScanner.scan();

    if (result.rawContent.isNotEmpty) {
      log('Scanned QR Code: ${result.rawContent}');

      context.read<AppState>().setState(
            (model) => model.copyWith(
              convexityAddress: Address.fromHex(result.rawContent),
            ),
          );
    } else {
      log('Scanned QR Code is empty. Will not set Convexity Address.');
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    var devUriStr =
        Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';

    return Container(
      padding: EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RadioListTile<Uri>(
                title: Text('convex.world'),
                subtitle: Text('https://convex.world'),
                value: convexWorldUri,
                groupValue: appState.model.convexServerUri,
                onChanged: (value) {
                  appState.setState((m) => m.copyWith(convexServerUri: value));
                },
              ),
              RadioListTile<Uri>(
                title: Text('dev'),
                subtitle: Text(devUriStr),
                value: Uri.parse(devUriStr),
                groupValue: appState.model.convexServerUri,
                onChanged: (value) {
                  appState.setState((m) => m.copyWith(convexServerUri: value));
                },
              ),
              // Convexity Address Input
              TextFormField(
                controller: convexityController,
                decoration: InputDecoration(
                  labelText: 'Convexity Address',
                ),
              ),
              Gap(20),
              Icon(
                Icons.qr_code,
                size: 80,
              ),
              TextButton(
                child: Text('Scan Convexity QR Code'),
                onPressed: () {
                  scan();
                },
              ),
              Gap(40),
              ElevatedButton(
                child: Text('Start'),
                onPressed: () {
                  appState.setState(
                    (model) => model.copyWith(
                      convexityAddress:
                          Address.fromHex(convexityController.text),
                    ),
                  );

                  nav.pushLauncher(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    convexityController.dispose();

    super.dispose();
  }
}
