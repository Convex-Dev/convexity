import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../format.dart';

class AssetScreen extends StatelessWidget {
  final AAsset aasset;

  const AssetScreen({Key key, this.aasset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AAsset can be passed directly to the constructor,
    // or via the Navigator arguments.
    AAsset _aasset =
        aasset ?? ModalRoute.of(context).settings.arguments as AAsset;

    var fungible = _aasset.asset as FungibleToken;

    return Scaffold(
      appBar: AppBar(title: Text('${fungible.metadata.symbol}')),
      body: AssetScreenBody(aasset: _aasset),
    );
  }
}

class AssetScreenBody extends StatefulWidget {
  final AAsset aasset;

  const AssetScreenBody({Key key, this.aasset}) : super(key: key);

  @override
  _AssetScreenBodyState createState() => _AssetScreenBodyState();
}

class _AssetScreenBodyState extends State<AssetScreenBody> {
  Future<int> balance;

  @override
  void initState() {
    super.initState();

    var appState = context.read<AppState>();

    var fungible = widget.aasset.asset as FungibleToken;

    // Check the user's balance for this Token.
    balance = appState.fungibleClient().balance(
          token: fungible.address,
          holder: appState.model.activeAddress,
        );
  }

  @override
  Widget build(BuildContext context) {
    var fungible = widget.aasset.asset as FungibleToken;

    return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fungible.metadata.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Gap(4),
                        Text(
                          fungible.metadata.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ],
                    ),
                    QrImage(
                      data: fungible.address.hex,
                      version: QrVersions.auto,
                      size: 80,
                    ),
                  ],
                ),
              ),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      Gap(4),
                      FutureBuilder(
                        future: balance,
                        builder: (context, snapshot) =>
                            snapshot.connectionState == ConnectionState.waiting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    formatFungibleCurrency(
                                      metadata: fungible.metadata,
                                      number: snapshot.data,
                                    ),
                                  ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        child: Text('Buy'),
                        onPressed: () => nav.pushFungibleTransfer(
                          context,
                          fungible,
                          balance,
                        ),
                      ),
                      Gap(6),
                      TextButton(
                        child: Text('Sell'),
                        onPressed: () => nav.pushFungibleTransfer(
                            context, fungible, balance),
                      ),
                      Gap(6),
                      TextButton(
                        child: Text('Transfer'),
                        onPressed: () => nav.pushFungibleTransfer(
                            context, fungible, balance),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Gap(20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent activity',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Gap(20),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Identicon2(
                              address: Address(hex: ''),
                              size: 40,
                            ),
                            Gap(10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Transfer'),
                                Gap(4),
                                Text(
                                  '0x1C12041962F2A419e0...',
                                  style: TextStyle(color: Colors.black38),
                                ),
                                Gap(4),
                                Text(
                                  'Amount: \$500',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Gap(20),
                        Row(
                          children: [
                            Identicon2(
                              address: Address(hex: '0x1C12041962F2A419e0'),
                              size: 40,
                            ),
                            Gap(10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Transfer'),
                                Gap(4),
                                Text(
                                  '0x1C12041962F2A419e0...',
                                  style: TextStyle(color: Colors.black38),
                                ),
                                Gap(4),
                                Text(
                                  'Amount: \$200',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Gap(20),
                        Row(
                          children: [
                            Identicon2(
                              address: Address(
                                  hex:
                                      '7ca01811AD52666AE256aE983E89Cc54c18157'),
                              size: 40,
                            ),
                            Gap(10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Transfer'),
                                Gap(4),
                                Text(
                                  '0x1C12041962F2A419e0...',
                                  style: TextStyle(color: Colors.black38),
                                ),
                                Gap(4),
                                Text(
                                  'Amount: \$200',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ));
  }
}
