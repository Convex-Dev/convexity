import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:tuple/tuple.dart';

import '../model.dart';
import '../format.dart';
import '../convex.dart';
import '../widget.dart';
import '../nav.dart' as nav;
import '../shop.dart' as shop;

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
        ModalRoute.of(context)?.settings.arguments as Tuple2<AAsset, Future>?;

    // AAsset and balance can be passed directly to the constructor,
    // or via Navigator arguments.
    AAsset _aasset = aasset ?? arguments!.item1;
    Future _balance = balance ?? arguments!.item2;

    final title = _aasset.type == AssetType.fungible
        ? (_aasset.asset as FungibleToken).metadata.tickerSymbol
        : (_aasset.asset as NonFungibleToken).metadata.name;

    return Scaffold(
      appBar: AppBar(title: Text('$title')),
      body: AssetScreenBody(aasset: _aasset, balance: _balance),
    );
  }
}

/// Interface for Fungible and Non-Fungible Tokens.
class AssetScreenBody extends StatefulWidget {
  final AAsset aasset;
  final Future balance;

  const AssetScreenBody({
    Key? key,
    required this.aasset,
    required this.balance,
  }) : super(key: key);

  @override
  _AssetScreenBodyState createState() => _AssetScreenBodyState();
}

class _AssetScreenBodyState extends State<AssetScreenBody> {
  /// Local balance set whenever this Widget asks to refresh.
  ///
  /// Balance semantics is based on the type of Asset - Fungible or Non-Fungible.
  ///
  /// See Fungible and Non-Fungible Widgets.
  Future? _balance;

  Future get balance => _balance ?? widget.balance;

  /// Check the user's balance for this Token.
  Future<dynamic> queryBalance(BuildContext context) {
    final appState = context.read<AppState>();

    return appState.assetLibrary.balance(
      asset: widget.aasset.asset.address,
      owner: appState.model.activeAddress,
    );
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        child: SafeArea(
          child: widget.aasset.type == AssetType.fungible
              ? _FungibleBody(
                  aasset: widget.aasset,
                  balance: balance,
                  refresh: () {
                    setState(() {
                      _balance = queryBalance(context);
                    });
                  })
              : _NonFungibleBody(
                  aasset: widget.aasset,
                  balance: balance,
                  refresh: () {
                    setState(() {
                      _balance = queryBalance(context);
                    });
                  }),
        ),
        onWillPop: () async {
          // Pop with a potentially updated balance.
          Navigator.pop(context, balance);

          return false;
        },
      );
}

class _FungibleBody extends StatelessWidget {
  final AAsset aasset;
  // A Fungible Asset balance is a number.
  final Future balance;
  final void Function() refresh;

  const _FungibleBody({
    Key? key,
    required this.aasset,
    required this.balance,
    required this.refresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final activities = appState.model.activities
        .where(
          (activity) {
            if (activity.type != ActivityType.transfer) {
              return false;
            }

            final a = activity.payload as FungibleTransferActivity;

            return a.token == aasset.asset;
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
          _Info(aasset: aasset),
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
                                  metadata: aasset.asset.metadata,
                                  number: snapshot.data as int,
                                ),
                              );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      child: Text('BUY'),
                      onPressed: () {
                        final future = nav.pushExchange(
                          context,
                          params: ExchangeParams(
                            action: ExchangeAction.buy,
                            ofToken: aasset.asset,
                          ),
                        );

                        future.then((value) {
                          refresh();
                        });
                      },
                    ),
                    TextButton(
                      child: Text('SELL'),
                      onPressed: () {
                        final future = nav.pushExchange(
                          context,
                          params: ExchangeParams(
                            action: ExchangeAction.sell,
                            ofToken: aasset.asset,
                          ),
                        );

                        future.then((value) {
                          refresh();
                        });
                      },
                    ),
                    TextButton(
                      child: Text('TRANSFER'),
                      onPressed: () {
                        final fungible = aasset.asset as FungibleToken?;

                        var future = nav.pushFungibleTransfer(
                          context,
                          fungible,
                          balance,
                        );

                        future.then((result) {
                          // Transfer will pop with a false value
                          // if the user didn't make a transfer.
                          if (result != false) {
                            refresh();
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
                      _FungibleTransferActivityView(
                    activity: activities[index],
                  ),
                ),
              ),
            ),
          ],
          if (appState.model.following.contains(aasset))
            _Unfollow(aasset: aasset)
          else
            _Follow(aasset: aasset),
        ],
      ),
    );
  }
}

class _NonFungibleBody extends StatelessWidget {
  final AAsset aasset;

  /// A Non-Fungible Asset balance is a set of Token IDs.
  final Future balance;

  /// A function which is called to update the balance (Token IDs).
  ///
  /// This function is called when the user taps
  /// on the refresh button or when poping a screen.
  final void Function() refresh;

  const _NonFungibleBody({
    Key? key,
    required this.aasset,
    required this.balance,
    required this.refresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final convexClient = appState.convexClient;

    final myListings = shop.myListings(
      convexClient: convexClient,
      myAddress: appState.model.activeAddress!,
    );

    return Padding(
      padding: defaultScreenPadding,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Info(aasset: aasset),
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
                  onPressed: refresh,
                ),
              ],
            ),
            Gap(10),
            FutureBuilder<dynamic>(
              // Query balance (Token IDs) and user Listings because IDs need to be combined.
              future: Future.wait([balance, myListings]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Sorry. It was not possible to check for Non-Fungible Tokens.',
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasData) {
                  // User NFT IDs.
                  final List<int> ids = snapshot.data.first.cast<int>();

                  // User Listings.
                  final List<shop.Listing> listings =
                      snapshot.data.last.cast<shop.Listing>();

                  // Combine IDs from NFTs and Listings - it's all about NFTs after all.
                  List<int> _combinedIds = List.from(ids)
                    ..addAll(listings.map((listing) => listing.asset.item2));

                  if (_combinedIds.isEmpty) {
                    return Expanded(
                      child: Column(
                        children: [
                          Text("You don't own any Non-Fungible Token."),
                        ],
                      ),
                    );
                  }

                  final columnCount = 2;

                  return Expanded(
                    child: AnimationLimiter(
                      child: GridView.count(
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        crossAxisCount: columnCount,
                        children: _combinedIds.asMap().entries.map(
                          (entry) {
                            final tokenId = entry.value;

                            final data = convexClient.query(
                              source:
                                  '(call ${aasset.asset.address} (get-token-data ${entry.value}))',
                            );

                            shop.Listing? listing;

                            try {
                              listing = listings.firstWhere(
                                  (element) => element.asset.item2 == tokenId);
                            } on StateError {
                              // Noop.
                            }

                            Widget tile = NonFungibleGridTile(
                              tokenId: tokenId,
                              data: data,
                              onTap: () {
                                // ---
                                // If there is a Listing for this Token ID, navigate to Listing screen.
                                // If there isn't a Listing for this Token ID, navigate to NFT screen.
                                // ---
                                var result = listing != null
                                    ? nav.pushListing(
                                        context,
                                        listing: listing,
                                      )
                                    : nav.pushNonFungibleToken(
                                        context,
                                        nonFungibleToken: aasset.asset,
                                        tokenId: tokenId,
                                        data: data,
                                      );

                                // Refresh after popping the screen.
                                result.then((result) {
                                  refresh();
                                });
                              },
                            );

                            return AnimationConfiguration.staggeredGrid(
                              position: entry.key,
                              duration: const Duration(milliseconds: 375),
                              columnCount: columnCount,
                              child: ScaleAnimation(
                                child: FadeInAnimation(
                                  child: listing != null
                                      ? ClipRect(
                                          child: Banner(
                                            message: 'For Sale',
                                            color: Colors.green,
                                            location: BannerLocation.topEnd,
                                            child: tile,
                                          ),
                                        )
                                      : tile,
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
                child: Text('Mint NFT'),
                onPressed: () {
                  // Navigate to new NFT screen.
                  final result = nav.pushNewNonFungibleToken(
                    context,
                    nonFungibleToken: aasset.asset as NonFungibleToken?,
                  );

                  // Refresh after popping the screen.
                  result.then((value) {
                    refresh();
                  });
                },
              ),
            ),
            if (appState.model.following.contains(aasset))
              _Unfollow(aasset: aasset)
            else
              _Follow(aasset: aasset),
          ],
        ),
      ),
    );
  }
}

/// Button Widget to follow an Asset.
///
/// Following is an app-state change.
class _Follow extends StatelessWidget {
  final AAsset aasset;

  const _Follow({Key? key, required this.aasset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        child: Text('Follow'),
        onPressed: () {
          appState.follow(aasset);

          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'You are following ${aasset.asset.metadata.name}',
                  overflow: TextOverflow.clip,
                ),
              ),
            );
        },
      ),
    );
  }
}

/// Button Widget to unfollow an Asset.
///
/// Unfollowing is an app-state change.
class _Unfollow extends StatelessWidget {
  final AAsset aasset;

  const _Unfollow({Key? key, required this.aasset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        child: Text('Unfollow'),
        onPressed: () {
          appState.unfollow(aasset);

          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Unfollowed ${aasset.asset.metadata.name}',
                  overflow: TextOverflow.clip,
                ),
              ),
            );
        },
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final AAsset aasset;

  const _Info({Key? key, required this.aasset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    aasset.asset.metadata.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  Gap(4),
                  Text(
                    aasset.asset.metadata.description,
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  Gap(4),
                  SelectableText(
                    aasset.asset.address.toString(),
                    showCursor: false,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
            ),
            QrImage(
              data: aasset.asset.address.value.toString(),
              version: QrVersions.auto,
              size: 80,
            ),
          ],
        ),
      ),
    );
  }
}

class _FungibleTransferActivityView extends StatelessWidget {
  final Activity activity;

  const _FungibleTransferActivityView({
    Key? key,
    required this.activity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
  }
}
