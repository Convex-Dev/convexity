import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';

class MyTokensScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Tokens'),
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "You can create your own tokens for business or personal use. Any token supply you create will be owned by you.",
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
              Expanded(
                child: AssetCollection(
                  assets: appState.model.myTokens,
                  empty: "You haven't created any fungible tokens yet",
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: defaultButtonHeight,
                child: ElevatedButton(
                  child: Text(
                    'Create Fungible Token',
                  ),
                  onPressed: () {
                    nav.pushNewToken(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
