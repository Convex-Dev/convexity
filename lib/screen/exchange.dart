import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../convex.dart';
import '../model.dart';
import '../widget.dart';
import '../nav.dart' as nav;

class ExchangeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ExchangeAction action = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Exchange')),
      body: Container(
        padding: defaultScreenPadding,
        child: ExchangeScreenBody(
          action: action,
        ),
      ),
    );
  }
}

class ExchangeScreenBody extends StatefulWidget {
  final ExchangeAction action;

  const ExchangeScreenBody({Key key, this.action}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExchangeScreenBodyState(
        action: action,
      );
}

class _ExchangeScreenBodyState extends State<ExchangeScreenBody> {
  final buyIndex = 0;
  final sellIndex = 1;

  ExchangeAction action;

  FungibleToken ofToken = FungibleToken(
    address: Address(-1),
    metadata: FungibleTokenMetadata(
      name: 'CVX',
      description: 'Convex Coin',
      symbol: 'CVX',
      currencySymbol: '\$',
      decimals: 2,
    ),
  );

  int amount;

  FungibleToken withToken = FungibleToken(
    address: Address(-1),
    metadata: FungibleTokenMetadata(
      name: 'CVX',
      description: 'Convex Coin',
      symbol: 'CVX',
      currencySymbol: '\$',
      decimals: 2,
    ),
  );

  _ExchangeScreenBodyState({ExchangeAction action}) {
    this.action = action ?? ExchangeAction.buy;
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
                onPressed: amount != null ? confirm : null,
              ),
            )
          ],
        ),
      ),
    );
  }

  String actionText() {
    switch (action) {
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
          action == ExchangeAction.buy,
          action == ExchangeAction.sell,
        ],
        onPressed: (i) {
          setState(() {
            action = i == 0 ? ExchangeAction.buy : ExchangeAction.sell;
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
                ofToken.metadata.symbol,
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
                        ofToken = fungible;
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
                  amount = int.tryParse(s);
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
                'CVX',
                style: Theme.of(context)
                    .textTheme
                    .caption
                    .copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                primary: Colors.orange,
                shape: CircleBorder(),
              ),
            ),
          ),
        ],
      );

  void confirm() async {
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
                      '${actionText()} $amount ${ofToken.metadata.name} with  ${withToken.metadata.name}?',
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
  }
}
