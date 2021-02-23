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

  var action;

  _ExchangeScreenBodyState({ExchangeAction action}) {
    this.action = action ?? ExchangeAction.buy;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Column(
          children: [
            Center(
              child: ToggleButtons(
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
              ),
            ),
            Gap(40),
            Row(
              children: [
                Text(action == ExchangeAction.buy ? 'Buy' : 'Sell'),
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
                    style: ElevatedButton.styleFrom(shape: CircleBorder()),
                  ),
                ),
                Gap(30),
                Text('Amount'),
                Gap(10),
                Expanded(
                  child: TextField(
                    onChanged: (s) {},
                  ),
                ),
              ],
            ),
            Gap(30),
            Row(
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
                    style: ElevatedButton.styleFrom(shape: CircleBorder()),
                  ),
                ),
              ],
            ),
            Gap(50),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text(
                  action == ExchangeAction.buy ? 'Buy' : 'Sell',
                ),
                onPressed: () {},
              ),
            )
          ],
        ),
      ),
    );
  }
}
