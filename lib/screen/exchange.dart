import 'package:flutter/material.dart';

import '../model.dart';
import '../widget.dart';

class ExchangeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ExchangeAction initialAction =
        ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Exchange')),
      body: Container(
        padding: defaultScreenPadding,
        child: ExchangeScreenBody(
          initialAction: initialAction,
        ),
      ),
    );
  }
}

class ExchangeScreenBody extends StatefulWidget {
  final ExchangeAction initialAction;

  const ExchangeScreenBody({Key key, this.initialAction}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExchangeScreenBodyState(
        initialAction: initialAction,
      );
}

class _ExchangeScreenBodyState extends State<ExchangeScreenBody> {
  final buyIndex = 0;
  final sellIndex = 1;

  var isSelected;

  _ExchangeScreenBodyState({ExchangeAction initialAction}) {
    final _initialAction = initialAction ?? ExchangeAction.buy;

    isSelected = [
      _initialAction == ExchangeAction.buy,
      _initialAction == ExchangeAction.sell,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: ToggleButtons(
            children: [
              Text('Buy'),
              Text('Sell'),
            ],
            isSelected: isSelected,
            onPressed: (i) {
              setState(() {
                isSelected = [i == buyIndex, i == sellIndex];
              });
            },
          ),
        ),
      ],
    );
  }
}
