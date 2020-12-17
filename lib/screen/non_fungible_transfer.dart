import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:tuple/tuple.dart';

import '../widget.dart';
import '../nav.dart';

class NonFungibleTransferScreen extends StatelessWidget {
  final NonFungibleToken nonFungibleToken;
  final int tokenId;

  const NonFungibleTransferScreen({
    Key key,
    this.nonFungibleToken,
    this.tokenId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var arguments = ModalRoute.of(context).settings.arguments
        as Tuple2<NonFungibleToken, int>;

    // Token can be passed directly to the constructor,
    // or via Navigator arguments.
    var _nonFungibleToken = nonFungibleToken ?? arguments.item1;
    var _tokenId = tokenId ?? arguments.item2;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Non-Fungible $_tokenId'),
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: NonFungibleTransferScreenBody(
          nonFungibleToken: _nonFungibleToken,
          tokenId: _tokenId,
        ),
      ),
    );
  }
}

class NonFungibleTransferScreenBody extends StatefulWidget {
  final NonFungibleToken nonFungibleToken;
  final int tokenId;

  const NonFungibleTransferScreenBody({
    Key key,
    this.nonFungibleToken,
    this.tokenId,
  }) : super(key: key);

  @override
  _NonFungibleTransferScreenBodyState createState() =>
      _NonFungibleTransferScreenBodyState();
}

class _NonFungibleTransferScreenBodyState
    extends State<NonFungibleTransferScreenBody> {
  final _formKey = GlobalKey<FormState>();
  final _receiverTextController = TextEditingController();

  Address get _receiver => _receiverTextController.text.isNotEmpty
      ? Address.fromHex(_receiverTextController.text)
      : null;

  @override
  Widget build(BuildContext context) {
    final replacement = SizedBox(
      width: 120,
      height: 120,
    );

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: _receiver != null,
              replacement: replacement,
              child: _receiver == null
                  ? replacement
                  : identicon(
                      _receiver.hex,
                      height: 120,
                      width: 120,
                    ),
            ),
            TextFormField(
              readOnly: true,
              controller: _receiverTextController,
              decoration: InputDecoration(
                labelText: 'To',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Required';
                }

                return null;
              },
              onTap: () {
                pushSelectAccount(context).then((selectedAddress) {
                  if (selectedAddress != null) {
                    setState(() {
                      _receiverTextController.text = selectedAddress.toString();
                    });
                  }
                });
              },
            ),
            Gap(30),
            Column(
              children: [
                Gap(20),
                SizedBox(
                  height: 60,
                  width: 100,
                  child: ElevatedButton(
                    child: Text('SEND'),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {}
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void dispose() {
    _receiverTextController.dispose();

    super.dispose();
  }
}
