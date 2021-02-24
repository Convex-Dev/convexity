import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../convex.dart';
import '../logger.dart';
import '../model.dart';
import '../widget.dart';
import '../nav.dart' as nav;
import '../route.dart' as route;

class ExchangeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ExchangeParams params = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Exchange')),
      body: Container(
        padding: defaultScreenPadding,
        child: ExchangeScreenBody(
          params: params,
        ),
      ),
    );
  }
}

class ExchangeScreenBody extends StatefulWidget {
  final ExchangeParams params;

  const ExchangeScreenBody({Key key, this.params}) : super(key: key);

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
      decimals: 2,
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
            return Column(
              children: [
                Center(child: actionToggle()),
                Gap(40),
                snapshot.connectionState == ConnectionState.waiting
                    ? CircularProgressIndicator()
                    : buyOrSellAmount(ofTokenPrice: snapshot.data),
                Gap(30),
                buyOrSellWith(),
                Gap(50),
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

  Widget buyOrSellAmount({double ofTokenPrice}) {
    if (ofTokenPrice == null) {
      return Row(
        children: [
          Text(
            'There is no liquidity for ${params.ofToken?.metadata?.symbol ?? ''}.',
          ),
          Gap(10),
          ElevatedButton(
            child: Text('Add liquidity'),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
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
        ],
      );
    }

    return Row(
      children: [
        Text(actionText()),
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
                      params = params.copyWith(ofToken: fungible);
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
        Gap(30),
        Text('Amount'),
        Gap(10),
        Expanded(
          child: TextField(
            onChanged: (s) {
              setState(() {
                params = params.copyWith(amount: int.tryParse(s));
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buyOrSellWith() => Row(
        children: [
          Text('With'),
          Gap(20),
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
        ],
      );

  void confirm() async {
    final confirmation = await showModalBottomSheet(
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
                      '${actionText()} $params.amount ${params.ofToken.metadata.name} with  ${params.withToken.metadata.name}?',
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

    if (params.action == ExchangeAction.buy) {
      final bought = appState.torus().buy(
            ofToken: params.ofToken.address,
            amount: params.amount,
            withToken: params.withToken.address,
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
  int tokenAmount;
  int cvxAmount;
  Future<int> liquidity;

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
                  widget.token.metadata.symbol,
                  style: Theme.of(context).textTheme.headline5,
                ),
                Text(
                  widget.token.metadata.name,
                  style: Theme.of(context).textTheme.caption,
                ),
                Gap(20),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount of ${widget.token.metadata.symbol}',
                    helperText: 'Helper text',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      tokenAmount = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                Gap(20),
                TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: 'Amount of CVX',
                    helperText: 'Helper text',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      cvxAmount = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                Gap(30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
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
