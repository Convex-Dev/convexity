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

  _ExchangeScreenBodyState({ExchangeParams params}) {
    this.params = params ?? ExchangeParams(action: ExchangeAction.buy);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Column(
          children: [
            Center(child: actionToggle()),
            Gap(40),
            buyOrSellAmount(),
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

  Widget buyOrSellAmount() => Row(
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
