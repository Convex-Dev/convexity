import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

import '../convex.dart';
import '../format.dart';
import '../logger.dart';
import '../model.dart';
import '../widget.dart';
import '../nav.dart' as nav;
import '../format.dart' as format;
import '../route.dart' as route;

class ExchangeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Tuple2<Future, ExchangeParams> t2 =
        ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Exchange')),
      body: Container(
        padding: defaultScreenPadding,
        child: ExchangeScreenBody(
          balance: t2.item1,
          params: t2.item2,
        ),
      ),
    );
  }
}

class ExchangeScreenBody extends StatefulWidget {
  final Future balance;
  final ExchangeParams params;

  const ExchangeScreenBody({
    Key key,
    this.balance,
    this.params,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExchangeScreenBodyState(
        params: params,
      );
}

class _ExchangeScreenBodyState extends State<ExchangeScreenBody> {
  final buyIndex = 0;
  final sellIndex = 1;

  final cvx = FungibleToken(
    address: Address(-1),
    metadata: FungibleTokenMetadata(
      name: 'CVX',
      description: 'Convex Coin',
      symbol: 'CVX',
      currencySymbol: '\$',
      decimals: 0,
    ),
  );

  ExchangeParams params;
  Future<double> ofTokenPrice;

  _ExchangeScreenBodyState({ExchangeParams params}) {
    this.params = params ?? ExchangeParams(action: ExchangeAction.buy);
  }

  @override
  void initState() {
    super.initState();

    if (params.ofToken?.address != null) {
      ofTokenPrice = context
          .read<AppState>()
          .torus()
          .price(ofToken: params.ofToken.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: FutureBuilder(
          future: ofTokenPrice,
          builder: (context, snapshot) {
            final isOfPriceAvailable =
                snapshot.connectionState != ConnectionState.waiting &&
                    snapshot.data != null;

            return Column(
              children: [
                Center(child: actionToggle()),
                Gap(40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FutureBuilder(
                      future: widget.balance,
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
                                  metadata: params.ofToken.metadata,
                                  number: snapshot.data,
                                ),
                                style: Theme.of(context).textTheme.headline5,
                              );
                      },
                    ),
                    Gap(2),
                    Text(
                      'BALANCE',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
                Gap(40),
                snapshot.connectionState == ConnectionState.waiting
                    ? CircularProgressIndicator()
                    : buyOrSellOf(ofTokenPrice: snapshot.data),
                Gap(50),
                if (isOfPriceAvailable) buyOrSellWith(),
                Gap(50),
                if (isOfPriceAvailable)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: Text(actionText()),
                      onPressed: params.amount != null ? confirm : null,
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }

  String actionText() {
    switch (params.action) {
      case ExchangeAction.buy:
        return 'Buy';
      case ExchangeAction.sell:
        return 'Sell';
    }

    return '?';
  }

  Widget actionToggle() => ToggleButtons(
        children: [
          Text('Buy'),
          Text('Sell'),
        ],
        isSelected: [
          params.action == ExchangeAction.buy,
          params.action == ExchangeAction.sell,
        ],
        onPressed: (i) {
          setState(() {
            params = params.copyWith(
              action: i == 0 ? ExchangeAction.buy : ExchangeAction.sell,
            );
          });
        },
      );

  Widget buyOrSellOf({double ofTokenPrice}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(actionText() + ' '),
            Gap(20),
            ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: 60, height: 60),
              child: ElevatedButton(
                child: Text(
                  params.ofToken?.metadata?.symbol ?? cvx.metadata.symbol,
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () {
                  nav.pushSelectFungible(context).then(
                    (fungible) {
                      if (fungible != null) {
                        setState(() {
                          this.params = params.copyWith(ofToken: fungible);
                          this.ofTokenPrice = context
                              .read<AppState>()
                              .torus()
                              .price(ofToken: params.ofToken.address);
                        });
                      }
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  shape: CircleBorder(),
                ),
              ),
            ),
            if (ofTokenPrice != null) ...[
              Gap(30),
              Text('Amount'),
              Gap(10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (s) {
                    setState(() {
                      params = params.copyWith(amount: s);
                    });
                  },
                ),
              )
            ] else ...[
              Gap(20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    child: Text('Add liquidity'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            padding: EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: SafeArea(
                                child: _TokenLiquidity(
                                  token: params.ofToken,
                                ),
                              ),
                            ),
                          );
                        },
                      ).then((value) {
                        if (value != null) {
                          setState(() {
                            this.ofTokenPrice = context
                                .read<AppState>()
                                .torus()
                                .price(ofToken: params.ofToken.address);
                          });
                        }
                      });
                    },
                  ),
                  Text(
                    'There is no liquidity for ${params.ofToken?.metadata?.symbol ?? ''}.',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              )
            ]
          ],
        ),
        if (ofTokenPrice != null) ...[
          Gap(10),
          Row(
            children: [
              Text(
                'Marginal Price',
                style: Theme.of(context).textTheme.caption,
              ),
              Gap(4),
              Text(
                '${NumberFormat().format(ofTokenPrice)}',
                style: Theme.of(context).textTheme.bodyText2,
              )
            ],
          )
        ],
      ],
    );
  }

  Widget buyOrSellWith() => Row(
        children: [
          Text('With'),
          Gap(20),
          // Select 'with' Token and query price.
          ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: 60, height: 60),
            child: ElevatedButton(
              child: Text(
                params.withToken?.metadata?.symbol ?? cvx.metadata.symbol,
                style: Theme.of(context)
                    .textTheme
                    .caption
                    .copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {
                nav.pushSelectFungible(context).then(
                  (fungible) {
                    if (fungible != null) {
                      setState(() {
                        params = params.copyWith(withToken: fungible);
                        ofTokenPrice = context.read<AppState>().torus().price(
                              ofToken: params.ofToken.address,
                              withToken: fungible.address,
                            );
                      });
                    }
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.orange,
                shape: CircleBorder(),
              ),
            ),
          ),
          Gap(10),
          // Reset 'with' Token and query price for CVX.
          if (params.withToken != null)
            ElevatedButton(
              child: Text(
                'Reset',
                style: Theme.of(context)
                    .textTheme
                    .caption
                    .copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {
                setState(() {
                  params = params.copyWith(withToken: null);

                  ofTokenPrice = context
                      .read<AppState>()
                      .torus()
                      .price(ofToken: params.ofToken.address);
                });
              },
            ),
        ],
      );

  void confirm() async {
    final confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) {
        final withToken = params.withToken ?? cvx;

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
                      '${actionText()} ${params.amount} ${params.ofToken.metadata.name} with  ${withToken.metadata.name}?',
                    ),
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

    final appState = context.read<AppState>();

    final withToken = params.withToken ?? cvx;

    final int amountOf = format.readFungibleCurrency(
      metadata: params.ofToken.metadata,
      s: params.amount,
    );

    if (params.action == ExchangeAction.buy) {
      final bought = appState.torus().buyTokens(
            ofToken: params.ofToken.address,
            amount: amountOf,
          );

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            child: Center(
              child: FutureBuilder(
                future: bought,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<int> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    logger.e(
                      'Failed to buy: ${snapshot.error}',
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
                            'Sorry. It was not possible to buy ${params.ofToken.metadata.symbol}.\n\n${snapshot.error}',
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
                              'Bought ${params.amount}.',
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
    } else {
      final sold = params.withToken == null
          ? appState.torus().sellTokens(
                ofToken: params.ofToken.address,
                amount: amountOf,
              )
          : appState.torus().sell(
                ofToken: params.ofToken.address,
                amount: amountOf,
                withToken: params.withToken?.address,
              );

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            child: Center(
              child: FutureBuilder<int>(
                future: sold,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<int> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    logger.e(
                      'Failed to sell: ${snapshot.error}',
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
                            'Sorry. It was not possible to sell ${params.ofToken.metadata.symbol}.\n\n${snapshot.error}',
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
                              'Sold ${snapshot.data}.',
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
  }
}

class _TokenLiquidity extends StatefulWidget {
  final FungibleToken token;

  const _TokenLiquidity({Key key, this.token}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TokenLiquidityState();
}

class _TokenLiquidityState extends State<_TokenLiquidity> {
  int tokenAmount = 0;
  int cvxAmount = 0;
  Future<int> liquidity;

  double get tokenPrice =>
      tokenAmount > 0 && cvxAmount > 0 ? tokenAmount / cvxAmount : null;

  double get cvxPrice =>
      tokenAmount > 0 && cvxAmount > 0 ? cvxAmount / tokenAmount : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: defaultScreenPadding,
      child: liquidity != null
          ? FutureBuilder<int>(
              future: liquidity,
              builder: (context, snapshot) {
                if (ConnectionState.waiting == snapshot.connectionState) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return Column(
                  children: [
                    Text(
                      '${snapshot.hasError ? snapshot.error : snapshot.data}',
                    ),
                    Gap(20),
                    ElevatedButton(
                      child: Text('Done'),
                      onPressed: () => Navigator.pop(context, snapshot.data),
                    )
                  ],
                );
              },
            )
          : Column(
              children: <Widget>[
                Text(
                  'Add liquidity for ${widget.token.metadata.symbol}',
                  style: Theme.of(context).textTheme.headline6,
                ),
                Text(
                  'Explanatory text.',
                  style: Theme.of(context).textTheme.caption,
                ),
                Gap(40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.token.metadata.symbol} BALANCE',
                      style: Theme.of(context).textTheme.caption,
                    ),
                    Gap(8),
                    Text(
                      '${widget.token.metadata.currencySymbol}10',
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ],
                ),
                Gap(5),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount of ${widget.token.metadata.symbol}',
                    helperText: 'Helper text',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      tokenAmount = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'CVX BALANCE',
                      style: Theme.of(context).textTheme.caption,
                    ),
                    Gap(5),
                    Text(
                      '1,000,000',
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ],
                ),
                Gap(5),
                TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: 'Amount of CVX',
                    helperText: 'Helper text',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      cvxAmount = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                Gap(30),
                Table(
                  children: [
                    TableRow(
                      children: [
                        TableCell(
                          child: Text(
                            '1 ${widget.token.metadata.symbol}',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        TableCell(
                          child: Text(
                            '=',
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        TableCell(
                          child: Text(
                            cvxPrice != null
                                ? '${NumberFormat().format(cvxPrice)} CVX'
                                : '-',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Text(
                            '1 CVX',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        TableCell(
                          child: Text(
                            '=',
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        TableCell(
                          child: Text(
                            tokenPrice != null
                                ? '$tokenPrice ${widget.token.metadata.symbol}'
                                : '-',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Gap(30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlineButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Gap(10),
                    ElevatedButton(
                      child: Text('Confirm'),
                      onPressed: tokenAmount != null &&
                              tokenAmount > 0 &&
                              cvxAmount != null &&
                              cvxAmount > 0
                          ? () {
                              setState(() {
                                liquidity = context
                                    .read<AppState>()
                                    .torus()
                                    .addLiquidity(
                                      token: widget.token.address,
                                      tokenAmount: tokenAmount,
                                      cvxAmount: cvxAmount,
                                    );
                              });
                            }
                          : null,
                    ),
                  ],
                )
              ],
            ),
    );
  }
}
