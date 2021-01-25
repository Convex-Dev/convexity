import 'package:flutter/material.dart';

import '../widget.dart';

class StakingScreen extends StatelessWidget {
  const StakingScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staking'),
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: StakingScreenBody(),
      ),
    );
  }
}

class StakingScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}
