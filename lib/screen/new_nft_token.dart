import 'package:flutter/material.dart';

import '../widget.dart';

class NewNonFungibleTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New NFT'),
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: NewNonFungibleTokenScreenBody(),
      ),
    );
  }
}

class NewNonFungibleTokenScreenBody extends StatefulWidget {
  @override
  _NewNonFungibleTokenScreenBodyState createState() =>
      _NewNonFungibleTokenScreenBodyState();
}

class _NewNonFungibleTokenScreenBodyState
    extends State<NewNonFungibleTokenScreenBody> {
  @override
  Widget build(BuildContext context) {
    return Text('NFT');
  }
}
