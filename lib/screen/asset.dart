import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../widget.dart';

class AssetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Asset')),
      body: AssetScreenBody(),
    );
  }
}

class AssetScreenBody extends StatefulWidget {
  @override
  _AssetScreenBodyState createState() => _AssetScreenBodyState();
}

class _AssetScreenBodyState extends State<AssetScreenBody> {
  var isLoading = false;
  var assets = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var following = context.watch<AppState>().model.following;

    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      children: following
          .map(
            (token) => Container(
              padding: const EdgeInsets.all(8),
              child: TokenRenderer(token: token),
            ),
          )
          .toList(),
    );
  }
}
