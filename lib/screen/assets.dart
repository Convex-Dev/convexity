import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AssetsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assets')),
      body: AssetsScreenBody(),
    );
  }
}

class AssetsScreenBody extends StatefulWidget {
  @override
  _AssetsScreenBodyState createState() => _AssetsScreenBodyState();
}

class _AssetsScreenBodyState extends State<AssetsScreenBody> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: QrImage(
          data: 'Convexity',
          version: QrVersions.auto,
          size: 200,
        ),
      ),
    );
  }
}
