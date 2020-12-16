import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/logger.dart';
import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../logger.dart';
import '../model.dart';
import '../nav.dart' as nav;
import '../format.dart';

Widget fungibleTransferActivityView(FungibleTransferActivity activity) =>
    StatelessWidgetBuilder((context) {
      final contacts = context.select(
        (AppState appState) => appState.model.contacts,
      );

      final toContact = contacts.firstWhere(
        (contact) => contact.address == activity.to,
        orElse: () => null,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Gap(20),
              Text(
                activity.timestamp.toString(),
                style: Theme.of(context).textTheme.caption,
              )
            ],
          ),
          Gap(4),
          Row(
            children: [
              identicon(
                activity.from.hex,
                height: 30,
                width: 30,
              ),
              Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Own Account',
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      activity.from.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.caption,
                    )
                  ],
                ),
              ),
              Gap(10),
              Icon(Icons.arrow_right_alt),
              Gap(10),
              identicon(
                activity.to.hex,
                height: 30,
                width: 30,
              ),
              Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toContact?.name?.toString() ?? 'Not in Address Book',
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      activity.to.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.caption,
                    )
                  ],
                ),
              )
            ],
          ),
          Gap(4),
          Text(
            'Amount: ${formatFungibleCurrency(metadata: activity.token.metadata, number: activity.amount)}',
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
        ],
      );
    });

class AssetScreen extends StatelessWidget {
  final AAsset aasset;

  const AssetScreen({Key key, this.aasset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AAsset can be passed directly to the constructor,
    // or via the Navigator arguments.
    AAsset _aasset =
        aasset ?? ModalRoute.of(context).settings.arguments as AAsset;

    final title = _aasset.type == AssetType.fungible
        ? (_aasset.asset as FungibleToken).metadata.symbol
        : (_aasset.asset as NonFungibleToken).metadata.name;

    return Scaffold(
      appBar: AppBar(title: Text('$title')),
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

  Widget _info() => StatelessWidgetBuilder((context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.aasset.asset.metadata.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    Gap(4),
                    Text(
                      widget.aasset.asset.metadata.description,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Gap(4),
                    SelectableText(
                      widget.aasset.asset.address.toString(),
                      showCursor: false,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
              ),
              QrImage(
                data: widget.aasset.asset.address.hex,
                version: QrVersions.auto,
                size: 80,
              ),
            ],
          ),
        ),
      ));

  Widget _action({
    @required String label,
    @required void Function() onPressed,
  }) =>
      StatelessWidgetBuilder(
        (context) => Column(
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
        ),
      );

  Widget _fungible() => StatelessWidgetBuilder((context) {
        final activities =
            context.watch<AppState>().model.activities.reversed.toList();

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _info(),
              Gap(20),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.aasset.type == AssetType.fungible)
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
                            builder: (context, snapshot) {
                              return snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      formatFungibleCurrency(
                                        metadata: widget.aasset.asset.metadata,
                                        number: snapshot.data,
                                      ),
                                    );
                            },
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        _action(
                          label: 'Buy',
                          onPressed: () {},
                        ),
                        Gap(30),
                        _action(
                          label: 'Sell',
                          onPressed: () {},
                        ),
                        Gap(30),
                        _action(
                          label: 'Transfer',
                          onPressed: () {
                            if (widget.aasset.type == AssetType.fungible) {
                              final fungible =
                                  widget.aasset.asset as FungibleToken;

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
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Gap(20),
              if (activities.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Recent activity',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    child: Card(
                      child: ListView.separated(
                        itemCount: activities.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.all(12),
                          child: fungibleTransferActivityView(
                            activities[index].payload
                                as FungibleTransferActivity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        );
      });

  Widget _nonFungible() => StatelessWidgetBuilder((context) {
        final appState = context.watch<AppState>();

        // Balance for NonFungible is a set of IDs.
        final balance = appState.assetLibrary().balance(
              asset: widget.aasset.asset.address as Address,
              owner: appState.model.activeAddress,
            );

        final convexClient = appState.convexClient();

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _info(),
              Gap(20),
              Text(
                'Tokens',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Gap(10),
              FutureBuilder(
                future: balance,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data;

                    if (data == null) {
                      return Text(
                        'Sorry. It was not possible to check for Non-Fungible Tokens.',
                      );
                    }

                    final ids = snapshot.data as List;

                    logger.d('Non-Fungible Tokens: $ids');

                    if (ids.isEmpty) {
                      return Text("You don't own any Non-Fungible Token.");
                    }

                    final columnCount = 4;

                    return Expanded(
                      child: AnimationLimiter(
                        child: GridView.count(
                          crossAxisCount: columnCount,
                          children: ids.asMap().entries.map(
                            (entry) {
                              final dataSource =
                                  '(call 0x${widget.aasset.asset.address.hex} (get-token-data ${entry.value}))';

                              final data =
                                  convexClient.query(source: dataSource);

                              return AnimationConfiguration.staggeredGrid(
                                position: entry.key,
                                duration: const Duration(milliseconds: 375),
                                columnCount: columnCount,
                                child: ScaleAnimation(
                                  child: FadeInAnimation(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Card(
                                            child: Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                margin: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.blue,
                                                ),
                                                child: Text(
                                                  entry.value.toString(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        FutureBuilder<Result>(
                                            future: data,
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Text(
                                                    snapshot.data.value['name'],
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .overline,
                                                  ),
                                                );
                                              }

                                              return Text('');
                                            }),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    );
                  }

                  return Center(child: CircularProgressIndicator());
                },
              )
            ],
          ),
        );
      });

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

    if (widget.aasset.type == AssetType.fungible) {
      balance = queryBalance(context);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.aasset.type == AssetType.fungible ? _fungible() : _nonFungible();
}
