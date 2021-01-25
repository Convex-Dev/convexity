import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class StakingScreenBody extends StatefulWidget {
  @override
  _StakingScreenBodyState createState() => _StakingScreenBodyState();
}

class _StakingScreenBodyState extends State<StakingScreenBody> {
  Future<Result> peers;

  @override
  void initState() {
    super.initState();

    final appState = context.read<AppState>();

    final s = '''
    (map 
      (fn [[a m]]
        [(str a) (:stake m) (:delegated-stake m)]) 
      (:peers *state*))
     ''';

    peers = appState.convexClient().query(source: s);
    peers.then((value) => print('Type ${value.value.runtimeType}'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}
