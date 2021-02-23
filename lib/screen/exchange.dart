import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../model.dart';
import '../widget.dart';

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
  Address ofToken;
  int amount;
  Address withToken;

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
                onPressed: () {},
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
}
