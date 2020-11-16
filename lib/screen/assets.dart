import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../backend.dart' as backend;
import '../nav.dart' as nav;
import '../config.dart' as config;
import '../widget.dart';

class AssetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assets')),
      body: AssetsScreenBody(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => nav.pushNewAsset(context),
      ),
    );
  }
}

class AssetsScreenBody extends StatefulWidget {
  @override
  _AssetsScreenBodyState createState() => _AssetsScreenBodyState();
}

class _AssetsScreenBodyState extends State<AssetsScreenBody> {
  var isLoading = true;
  var assets = [];

  @override
  void initState() {
    super.initState();

    backend.queryAssets(config.convexityAddress).then(
          (assets) => setState(
            () {
              this.isLoading = false;
              this.assets = assets;
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: assets
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
}
