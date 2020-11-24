import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../model.dart';

class AssetScreen extends StatelessWidget {
  final AssetMetadata metadata;

  const AssetScreen({Key key, this.metadata}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Metadata can be passed directly to the constructor,
    // or via the Navigator arguments.
    AssetMetadata _metadata =
        metadata ?? ModalRoute.of(context).settings.arguments as AssetMetadata;

    return Scaffold(
      appBar: AppBar(title: Text('Asset')),
      body: AssetScreenBody(metadata: _metadata),
    );
  }
}

class AssetScreenBody extends StatefulWidget {
  final AssetMetadata metadata;

  const AssetScreenBody({Key key, this.metadata}) : super(key: key);

  @override
  _AssetScreenBodyState createState() =>
      _AssetScreenBodyState(metadata: metadata);
}

class _AssetScreenBodyState extends State<AssetScreenBody> {
  final AssetMetadata metadata;

  _AssetScreenBodyState({this.metadata});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Asset');
  }
}
