import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widget.dart';
import '../model.dart';
import '../nav.dart' as nav;

class SocialCurrencyScreen extends StatelessWidget {
  const SocialCurrencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Social Currency'),
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: appState.model.socialCurrency != null
            ? Column(
                children: [
                  Center(child: Text(appState.model.socialCurrency.toString())),
                ],
              )
            : Center(
                child: ElevatedButton(
                  child: const Text('Create Social Currency'),
                  onPressed: () {
                    nav.pushNewSocialCurrency(context);
                  },
                ),
              ),
      ),
    );
  }
}
