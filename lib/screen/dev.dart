import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../nav.dart' as nav;
import '../model.dart';
import '../convex.dart';

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

  var convexityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    final convexityAddress = appState.model.convexityAddress;

    if (convexityController.text.isEmpty) {
      convexityController.text = convexityAddress.toString();
    }

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
                  appState.setState(
                      (m) => m.copyWith(convexServerUri: () => value!));
                },
              ),
              RadioListTile<Uri>(
                title: Text('dev'),
                subtitle: Text(devUriStr),
                value: Uri.parse(devUriStr),
                groupValue: appState.model.convexServerUri,
                onChanged: (value) {
                  appState.setState(
                    (m) => m.copyWith(
                      convexServerUri: () => value!,
                    ),
                  );
                },
              ),
              // Convexity Address Input
              TextFormField(
                controller: convexityController,
                decoration: InputDecoration(
                  labelText: 'Convexity Address',
                ),
              ),
              Gap(40),
              ElevatedButton(
                child: Text('Start'),
                onPressed: () {
                  appState.setState(
                    (model) => model.copyWith(
                      convexityAddress: () =>
                          Address.fromStr(convexityController.text),
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
