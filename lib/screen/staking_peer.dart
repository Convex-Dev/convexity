import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../widget.dart';

class StakingPeerScreen extends StatelessWidget {
  final Peer peer;

  const StakingPeerScreen({Key key, this.peer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Peer _peer = peer ?? ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(_peer.address.toString()),
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
