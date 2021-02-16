import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:tuple/tuple.dart';
import 'package:provider/provider.dart';

import '../logger.dart';
import '../model.dart';
import '../widget.dart';
import '../nav.dart';
import '../convex.dart';
import '../route.dart' as route;

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

  Address2 get _receiver => _receiverTextController.text.isNotEmpty
      ? Address2.fromStr(_receiverTextController.text)
      : null;

  void _send(BuildContext context) async {
    var appState = context.read<AppState>();

    // Modal to ask for confirmation.
    var confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.help,
                size: 80,
                color: Colors.black12,
              ),
              Gap(10),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Transfer Token ID ${widget.tokenId} to ',
                    ),
                    Identicon2(
                      address: Address2.fromStr(_receiverTextController.text),
                      isAddressVisible: true,
                      size: 30,
                    ),
                    Text(
                      '?',
                    )
                  ],
                ),
              ),
              Gap(10),
              ElevatedButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              )
            ],
          ),
        );
      },
    );

    if (confirmation != true) {
      return;
    }

    // Asset transfer.
    var transferInProgress = appState.assetLibrary().transferNonFungible(
      holder: appState.model.activeAddress2,
      holderSecretKey: appState.model.activeKeyPair.sk,
      holderAccountKey: appState.model.activeAccountKey,
      receiver: _receiver,
      nft: widget.nonFungibleToken.address,
      tokens: {
        widget.tokenId,
      },
    );

    // Modal to show transfer result.
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Center(
            child: FutureBuilder(
              future: transferInProgress,
              builder: (
                BuildContext context,
                AsyncSnapshot<Result> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.data?.errorCode != null) {
                  logger.e(
                    'Non-Fungible transfer returned an error: ${snapshot.data.errorCode} ${snapshot.data.value}',
                  );

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.error,
                        size: 80,
                        color: Colors.black12,
                      ),
                      Gap(10),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Sorry. Your transfer could not be completed.',
                        ),
                      ),
                      Gap(10),
                      ElevatedButton(
                        child: const Text('Okay'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  );
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.check,
                      size: 80,
                      color: Colors.green,
                    ),
                    Gap(10),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Transfered Token ID ${widget.tokenId} to ',
                          ),
                          aidenticon(
                            _receiver,
                            width: 30,
                            height: 30,
                          ),
                        ],
                      ),
                    ),
                    Gap(10),
                    ElevatedButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.popUntil(
                          context,
                          ModalRoute.withName(route.asset),
                        );
                      },
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

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
                  : aidenticon(
                      _receiver,
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
                      if (_formKey.currentState.validate()) {
                        _send(context);
                      }
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
