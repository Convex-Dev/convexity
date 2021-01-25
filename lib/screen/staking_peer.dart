import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../widget.dart';

class StakingPeerScreen extends StatelessWidget {
  const StakingPeerScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staking'),
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: StakingPeerScreenBody(),
      ),
    );
  }
}

class StakingPeerScreenBody extends StatefulWidget {
  @override
  _StakingPeerScreenBodyState createState() => _StakingPeerScreenBodyState();
}

class _StakingPeerScreenBodyState extends State<StakingPeerScreenBody> {
  @override
  Widget build(BuildContext context) {
    return Text('Bla');
  }
}
