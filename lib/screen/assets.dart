import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';

class AssetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    var assets = <AAsset>{}
      ..addAll(appState.model.myTokens)
      ..addAll(appState.model.following);

    return Scaffold(
      appBar: AppBar(title: Text('Assets')),
      body: Container(
        padding: defaultScreenPadding,
        child: AssetsCollection(assets: assets),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => nav.pushFollow(context),
      ),
    );
  }
}
