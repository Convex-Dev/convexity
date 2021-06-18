import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;

class SocialCurrencyScreen extends StatelessWidget {
  const SocialCurrencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    print(appState.model.socialCurrency);

    return Scaffold(
      appBar: AppBar(
        title: Text('Social Currency'),
      ),
      body: appState.model.socialCurrency != null
          ? Text(appState.model.socialCurrency.toString())
          : Center(
              child: ElevatedButton(
                child: const Text('Create Social Currency'),
                onPressed: () {
                  nav.pushNewSocialCurrency(context);
                },
              ),
            ),
    );
  }
}
