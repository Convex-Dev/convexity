import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:tuple/tuple.dart';

import '../logger.dart';
import '../model.dart';
import '../format.dart';
import '../convex.dart';
import '../widget.dart';
import '../nav.dart' as nav;

Widget fungibleTransferActivityView(Activity activity) =>
    StatelessWidgetBuilder((context) {
      final fungibleTransferActivity =
          activity.payload as FungibleTransferActivity;

      final appState = context.watch<AppState>();

      return Card(
        child: InkWell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
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
                      defaultDateTimeFormat(fungibleTransferActivity.timestamp),
                      style: Theme.of(context).textTheme.caption,
                    )
                  ],
                ),
                Gap(4),
                Row(
                  children: [
                    aidenticon(
                      fungibleTransferActivity.from!,
                      height: 30,
                      width: 30,
                    ),
                    Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState
                                    .findContact(fungibleTransferActivity.from)
                                    ?.name ??
                                'Not in Address Book',
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            fungibleTransferActivity.from.toString(),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    Gap(10),
                    Icon(Icons.arrow_right_alt),
                    Gap(10),
                    aidenticon(
                      fungibleTransferActivity.to!,
                      height: 30,
                      width: 30,
                    ),
                    Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState
                                    .findContact(fungibleTransferActivity.to)
                                    ?.name ??
                                'Not in Address Book',
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            fungibleTransferActivity.to.toString(),
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
                  'Amount: ${formatFungibleCurrency(
                    metadata: fungibleTransferActivity.token!.metadata,
                    number: fungibleTransferActivity.amount,
                  )}',
                  style: TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            nav.pushActivity(
              context,
              activity: activity,
            );
          },
        ),
      );
    });

class AssetScreen extends StatelessWidget {
  final AAsset? aasset;
  final Future? balance;

  const AssetScreen({
    Key? key,
    this.aasset,
    this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Tuple2<AAsset, Future>?;

    // AAsset and balance can be passed directly to the constructor,
    // or via the Navigator arguments.
    AAsset _aasset = aasset ?? arguments!.item1;
    Future _balance = balance ?? arguments!.item2;

    final title = _aasset.type == AssetType.fungible
        ? (_aasset.asset as FungibleToken).metadata.symbol
        : (_aasset.asset as NonFungibleToken).metadata.name;

    return Scaffold(
      appBar: AppBar(title: Text('$title')),
      body: AssetScreenBody(aasset: _aasset, balance: _balance),
    );
  }
}

class AssetScreenBody extends StatefulWidget {
  final AAsset? aasset;
  final Future? balance;

  const AssetScreenBody({
    Key? key,
    this.aasset,
    this.balance,
  }) : super(key: key);

  @override
  _AssetScreenBodyState createState() => _AssetScreenBodyState();
}

class _AssetScreenBodyState extends State<AssetScreenBody> {
  Future? _balance;

  Future? get balance => _balance ?? widget.balance;

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
                      widget.aasset!.asset.metadata.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    Gap(4),
                    Text(
                      widget.aasset!.asset.metadata.description,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Gap(4),
                    SelectableText(
                      widget.aasset!.asset.address.toString(),
                      showCursor: false,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
              ),
              QrImage(
                data: widget.aasset!.asset.address.value.toString(),
                version: QrVersions.auto,
                size: 80,
              ),
            ],
          ),
        ),
      ));

  Widget _action({
    required String label,
    required void Function() onPressed,
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

  Widget _follow(
    BuildContext context,
    AppState appState,
  ) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          child: Text('Follow'),
          onPressed: () {
            appState.follow(widget.aasset);

            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'You are following ${widget.aasset!.asset.metadata.name}',
                    overflow: TextOverflow.clip,
                  ),
                ),
              );
          },
        ),
      );

  Widget _unfollow(
    BuildContext context,
    AppState appState,
  ) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          child: Text('Unfollow'),
          onPressed: () {
            appState.unfollow(widget.aasset);

            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Unfollowed ${widget.aasset!.asset.metadata.name}',
                    overflow: TextOverflow.clip,
                  ),
                ),
              );
          },
        ),
      );

  Widget _fungible() => StatelessWidgetBuilder((context) {
        final appState = context.watch<AppState>();

        final activities = appState.model.activities
            .where(
              (activity) {
                if (activity.type != ActivityType.transfer) {
                  return false;
                }

                final a = activity.payload as FungibleTransferActivity;

                return a.token == widget.aasset!.asset;
              },
            )
            .toList()
            .reversed
            .toList();

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
                                      metadata: widget.aasset!.asset.metadata,
                                      number: snapshot.data as int,
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
                          onPressed: () {
                            final future = nav.pushExchange(
                              context,
                              params: ExchangeParams(
                                action: ExchangeAction.buy,
                                ofToken: widget.aasset!.asset,
                              ),
                            );

                            future.then((value) {
                              setState(() {
                                _balance = queryBalance(context);
                              });
                            });
                          },
                        ),
                        Gap(30),
                        _action(
                          label: 'Sell',
                          onPressed: () {
                            final future = nav.pushExchange(
                              context,
                              params: ExchangeParams(
                                action: ExchangeAction.sell,
                                ofToken: widget.aasset!.asset,
                              ),
                            );

                            future.then((value) {
                              setState(() {
                                _balance = queryBalance(context);
                              });
                            });
                          },
                        ),
                        Gap(30),
                        _action(
                          label: 'Transfer',
                          onPressed: () {
                            final fungible =
                                widget.aasset!.asset as FungibleToken?;

                            var future = nav.pushFungibleTransfer(
                              context,
                              fungible,
                              balance,
                            );

                            future.then((result) {
                              // Transfer will pop with a false value
                              // if the user didn't make a transfer.
                              if (result != false) {
                                setState(() {
                                  _balance = queryBalance(context);
                                });
                              }
                            });
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
                    child: ListView.separated(
                      itemCount: activities.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                      itemBuilder: (context, index) =>
                          fungibleTransferActivityView(activities[index]),
                    ),
                  ),
                ),
              ],
              if (appState.model.following.contains(widget.aasset))
                _unfollow(context, appState)
              else
                _follow(context, appState),
            ],
          ),
        );
      });

  Widget _nonFungible() => StatelessWidgetBuilder((context) {
        final appState = context.watch<AppState>();

        final convexClient = appState.convexClient();

        return Padding(
          padding: defaultScreenPadding,
          child: SafeArea(
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
                          _balance = queryBalance(context);
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
                                    '(call ${widget.aasset!.asset.address} (get-token-data ${entry.value}))';

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
                ),
                Gap(10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text('New Token'),
                    onPressed: () {
                      final result = nav.pushNewNonFungibleToken(
                        context,
                        nonFungibleToken:
                            widget.aasset!.asset as NonFungibleToken?,
                      );

                      result.then(
                        (value) => setState(() {
                          _balance = queryBalance(context);
                        }),
                      );
                    },
                  ),
                ),
                if (appState.model.following.contains(widget.aasset))
                  _unfollow(context, appState)
                else
                  _follow(context, appState),
              ],
            ),
          ),
        );
      });

  Widget _nonFungibleImage(String uri) {
    final fallback = Icon(
      Icons.image,
      size: 40,
    );

    try {
      if (Uri.parse(uri).isAbsolute == false) {
        return fallback;
      }

      return FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: uri,
      );
    } catch (e) {
      logger.e('Failed to load image: $e');

      return fallback;
    }
  }

  Widget _nonFungibleToken({
    int? tokenId,
    Future<Result>? data,
  }) =>
      FutureBuilder<Result>(
        future: data,
        builder: (context, snapshot) {
          final subtitle = AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: snapshot.connectionState == ConnectionState.waiting
                ? Text('')
                : (snapshot.data!.errorCode != null
                    ? Text('')
                    : Text(snapshot.data!.value['name'])),
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
                : (snapshot.data!.value['uri'] == null
                    ? Icon(
                        Icons.image,
                        size: 40,
                      )
                    : _nonFungibleImage(snapshot.data!.value['uri'])),
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
                nonFungibleToken: widget.aasset!.asset,
                tokenId: tokenId,
                data: data,
              );

              f.then(
                (result) {
                  // Query balance when 'returning' from a Transfer (result is null).
                  if (result == null) {
                    // Query the potentially updated balance.
                    setState(() {
                      _balance = queryBalance(context);
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
    final appState = context.read<AppState>();

    return appState.assetLibrary().balance(
          asset: widget.aasset!.asset.address,
          owner: appState.model.activeAddress,
        );
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        child: SafeArea(
          child: widget.aasset!.type == AssetType.fungible
              ? _fungible()
              : _nonFungible(),
        ),
        onWillPop: () async {
          // Pop with a potentially updated balance.
          Navigator.pop(context, balance);

          return false;
        },
      );
}
