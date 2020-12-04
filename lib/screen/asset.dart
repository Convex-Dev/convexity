import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/logger.dart';
import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../format.dart';

Widget fungibleTransferRenderer(FungibleTransferActivity activity) {
  return StatelessWidgetBuilder((context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transfer'),
        Gap(4),
        Identicon2(
          address: activity.to,
          isAddressVisible: true,
          size: 40,
        ),
        Gap(4),
        Text(
          'Amount: ${formatFungibleCurrency(metadata: activity.token.metadata, number: activity.amount)}',
          style: TextStyle(color: Colors.black87),
        ),
      ],
    );
  });
}

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

  /// Check the user's balance for this Token.
  Future<int> queryBalance(BuildContext context) {
    var appState = context.read<AppState>();

    var fungible = widget.aasset.asset as FungibleToken;

    // Check the user's balance for this Token.
    return appState.fungibleClient().balance(
          token: fungible.address,
          holder: appState.model.activeAddress,
        );
  }

  @override
  void initState() {
    super.initState();

    balance = queryBalance(context);
  }

  @override
  Widget build(BuildContext context) {
    var fungible = widget.aasset.asset as FungibleToken;

    var activities = context.watch<AppState>().model.activities;

    logger.d('Activities $activities');

    Widget action(
      BuildContext context, {
      @required String label,
      @required void Function() onPressed,
    }) =>
        Column(
          children: [
            Ink(
              decoration: const ShapeDecoration(
                color: Colors.lightBlue,
                shape: CircleBorder(),
              ),
              child: IconButton(
                icon: Icon(Icons.money),
                color: Colors.white,
                onPressed: onPressed,
              ),
            ),
            Gap(6),
            Text(label)
          ],
        );

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
                    action(
                      context,
                      label: 'Buy',
                      onPressed: () => nav.pushFungibleTransfer(
                        context,
                        fungible,
                        balance,
                      ),
                    ),
                    Gap(30),
                    action(
                      context,
                      label: 'Sell',
                      onPressed: () => nav.pushFungibleTransfer(
                        context,
                        fungible,
                        balance,
                      ),
                    ),
                    Gap(30),
                    action(
                      context,
                      label: 'Transfer',
                      onPressed: () {
                        var fnull = nav.pushFungibleTransfer(
                          context,
                          fungible,
                          balance,
                        );

                        fnull.then(
                          (_) {
                            // Query the potentially updated balance.
                            setState(() {
                              balance = queryBalance(context);
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Gap(20),
          if (activities.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      direction: Axis.vertical,
                      spacing: 20,
                      children: [
                        Text(
                          'Recent activity',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        ...activities
                            .map(
                              (e) => fungibleTransferRenderer(
                                e.payload as FungibleTransferActivity,
                              ),
                            )
                            .toList()
                      ],
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
