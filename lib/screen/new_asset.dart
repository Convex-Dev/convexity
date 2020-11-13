import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum _Option {
  recommended,
  scanQRCode,
  search,
  myHoldings,
  assetId,
}

class NewAssetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Asset')),
      body: NewAssetScreenBody(),
    );
  }
}

class NewAssetScreenBody extends StatefulWidget {
  @override
  _NewAssetScreenBodyState createState() => _NewAssetScreenBodyState();
}

class _NewAssetScreenBodyState extends State<NewAssetScreenBody> {
  var selectedOption = _Option.recommended;

  Widget option({
    @required String title,
    @required _Option value,
  }) =>
      RadioListTile(
        title: Text(title),
        value: value,
        groupValue: selectedOption,
        onChanged: (value) {
          setState(() {
            selectedOption = value;
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          option(
            title: 'Recommended',
            value: _Option.recommended,
          ),
          option(
            title: 'Scan QR Code',
            value: _Option.scanQRCode,
          ),
          option(
            title: 'Search',
            value: _Option.search,
          ),
          option(
            title: 'My Holdings',
            value: _Option.myHoldings,
          ),
          option(
            title: 'Entry Asset ID',
            value: _Option.assetId,
          ),
          Gap(20),
          OptionRenderer(
            option: selectedOption,
          )
        ],
      ),
    );
  }
}

class OptionRenderer extends StatelessWidget {
  final _Option option;

  const OptionRenderer({Key key, this.option}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (option) {
      case _Option.recommended:
        return _Recommended();
      case _Option.scanQRCode:
        return _ScanQRCode();
      case _Option.search:
        return _Search();
      case _Option.myHoldings:
        return _MyHoldings();
      case _Option.assetId:
        return _AssetID();
    }

    throw Exception("No renderer for $option");
  }
}

class _Recommended extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Recommended'),
    );
  }
}

class _ScanQRCode extends StatelessWidget {
  void scan() async {
    var result = await BarcodeScanner.scan();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QrImage(
          data: 'Convexity',
          version: QrVersions.auto,
          size: 160,
        ),
        ElevatedButton(
          child: Text('Scan QR Code'),
          onPressed: () {
            scan();
          },
        ),
      ],
    );
  }
}

class _Search extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Search'),
    );
  }
}

class _MyHoldings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('My Holdings'),
    );
  }
}

class _AssetID extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Asset ID'),
    );
  }
}
