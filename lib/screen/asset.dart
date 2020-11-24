import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../model.dart';

class AssetScreen extends StatelessWidget {
  final AAsset aasset;

  const AssetScreen({Key key, this.aasset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Metadata can be passed directly to the constructor,
    // or via the Navigator arguments.
    AAsset _metadata =
        aasset ?? ModalRoute.of(context).settings.arguments as AAsset;

    return Scaffold(
      appBar: AppBar(title: Text('Asset')),
      body: AssetScreenBody(aasset: _metadata),
    );
  }
}

class AssetScreenBody extends StatefulWidget {
  final AAsset aasset;

  const AssetScreenBody({Key key, this.aasset}) : super(key: key);

  @override
  _AssetScreenBodyState createState() => _AssetScreenBodyState(aasset: aasset);
}

class _AssetScreenBodyState extends State<AssetScreenBody> {
  final AAsset aasset;

  _AssetScreenBodyState({this.aasset});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Asset');
  }
}
