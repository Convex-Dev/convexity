import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';

class AssetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final assets = <AAsset>{}
      ..addAll(appState.model.myTokens)
      ..addAll(appState.model.following);

    return Scaffold(
      appBar: AppBar(title: Text('Follow Assets')),
      body: Container(
        padding: defaultScreenPadding,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: AssetsCollection(assets: assets)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('Follow'),
                  onPressed: () {
                    nav.pushFollow(context);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
