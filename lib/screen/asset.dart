import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:transparent_image/transparent_image.dart';

import '../model.dart';
import '../format.dart';
import '../convex.dart';
import '../widget.dart';
import '../nav.dart' as nav;

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
      floatingActionButton: _aasset.type == AssetType.nonFungible
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () => nav.pushNewNonFungibleToken(
                context,
                nonFungibleToken: _aasset.asset as NonFungibleToken,
              ),
            )
          : null,
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
  Future<dynamic> balance;

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
          padding: defaultScreenPadding,
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
                            final fungible =
                                widget.aasset.asset as FungibleToken;

                            var f = nav.pushFungibleTransfer(
                              context,
                              fungible,
                              balance,
                            );

                            f.then(
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

        final convexClient = appState.convexClient();

        return Padding(
          padding: defaultScreenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _info(),
              Gap(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tokens',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        balance = queryBalance(context);
                      });
                    },
                  ),
                ],
              ),
              Gap(10),
              FutureBuilder(
                future: balance,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Sorry. It was not possible to check for Non-Fungible Tokens.',
                    );
                  }

                  if (snapshot.hasData) {
                    final ids = snapshot.data as List;

                    if (ids.isEmpty) {
                      return Text("You don't own any Non-Fungible Token.");
                    }

                    final columnCount = 2;

                    return Expanded(
                      child: AnimationLimiter(
                        child: GridView.count(
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
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
                                    child: _nonFungibleToken(
                                      tokenId: entry.value as int,
                                      data: data,
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

                  return Text(
                    'Sorry. It was not possible to check for Non-Fungible Tokens.',
                  );
                },
              )
            ],
          ),
        );
      });

  Widget _nonFungibleToken({
    int tokenId,
    Future<Result> data,
  }) =>
      FutureBuilder<Result>(
        future: data,
        builder: (context, snapshot) {
          final subtitle = AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: snapshot.connectionState == ConnectionState.waiting
                ? Text('')
                : (snapshot.data.errorCode != null
                    ? Text('')
                    : Text(snapshot.data.value['name'])),
          );

          final child = AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: snapshot.connectionState == ConnectionState.waiting
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : (snapshot.data.value['uri'] == null
                    ? Icon(
                        Icons.image,
                        size: 40,
                      )
                    : FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: snapshot.data.value['uri'],
                      )),
          );

          return InkWell(
            child: GridTile(
              footer: GridTileBar(
                title: Text('#$tokenId'),
                subtitle: subtitle,
                backgroundColor: Colors.black45,
              ),
              child: child,
            ),
            onTap: () {
              final f = nav.pushNonFungibleToken(
                context,
                nonFungibleToken: widget.aasset.asset,
                tokenId: tokenId,
                data: data,
              );

              f.then(
                (result) {
                  // Query balance when 'returning' from a Transfer (result is null).
                  if (result == null) {
                    // Query the potentially updated balance.
                    setState(() {
                      balance = queryBalance(context);
                    });
                  }
                },
              );
            },
          );
        },
      );

  /// Check the user's balance for this Token.
  Future<dynamic> queryBalance(BuildContext context) {
    var appState = context.read<AppState>();

    return appState.assetLibrary().balance(
          asset: widget.aasset.asset.address,
          owner: appState.model.activeAddress,
        );
  }

  @override
  void initState() {
    super.initState();

    balance = queryBalance(context);
  }

  @override
  Widget build(BuildContext context) =>
      widget.aasset.type == AssetType.fungible ? _fungible() : _nonFungible();
}
