import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

    peers = appState.convexClient().query(source: '(:peers *state*)');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result>(
      future: peers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final sorted = (snapshot.data.value as Map).entries.toList()
          ..sort((a, b) => b.value['stake'].compareTo(a.value['stake']));

        final tiles = sorted.map(
          (e) {
            final m = e.value as Map<String, dynamic>;

            return ListTile(
              leading: Icon(Icons.computer),
              title: Text(
                e.key.toString(),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Stake: ' + NumberFormat().format(m['stake'] ?? 0),
              ),
            );
          },
        ).toList();

        return ListView(
          children: [
            ListTile(
              title: Text(
                'Peers',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            ...tiles,
          ],
        );
      },
    );
  }
}
