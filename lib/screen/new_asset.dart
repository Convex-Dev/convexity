import 'package:flutter/material.dart';

enum _EntryType {
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
  var selectedType = _EntryType.recommended;

  Widget option({
    @required String title,
    @required _EntryType value,
  }) =>
      RadioListTile(
        title: Text(title),
        value: value,
        groupValue: selectedType,
        onChanged: (value) {
          setState(() {
            selectedType = value;
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
            value: _EntryType.recommended,
          ),
          option(
            title: 'Scan QR Code',
            value: _EntryType.scanQRCode,
          ),
          option(
            title: 'Search',
            value: _EntryType.search,
          ),
          option(
            title: 'My Holdings',
            value: _EntryType.myHoldings,
          ),
          option(
            title: 'Entry Asset ID',
            value: _EntryType.assetId,
          ),
        ],
      ),
    );
  }
}
