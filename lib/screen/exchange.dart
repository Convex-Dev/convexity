import 'package:flutter/material.dart';

import '../widget.dart';

class ExchangeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exchange')),
      body: Container(
        padding: defaultScreenPadding,
        child: ExchangeScreenBody(),
      ),
    );
  }
}

class ExchangeScreenBody extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ExchangeScreenBodyState();
}

class _ExchangeScreenBodyState extends State<ExchangeScreenBody> {
  final buyIndex = 0;
  final sellIndex = 1;

  var isSelected = [true, false];

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
