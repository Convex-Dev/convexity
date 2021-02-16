import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../widget.dart';
import '../nav.dart' as nav;

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

    peers = appState.convexClient().query2(
          address: appState.model.activeAddress2,
          source: '(:peers *state*)',
        );
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

        final peers = (snapshot.data.value as Map).entries.map((e) {
          final m = e.value as Map<String, dynamic>;

          return Peer.fromJson(m..addAll({'address': e.key}));
        });

        final sorted = peers.toList()
          ..sort((a, b) => b.stake.compareTo(a.stake));

        final tiles = sorted.map(
          (peer) {
            return ListTile(
              leading: Icon(Icons.computer),
              title: Text(
                peer.address.toString(),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Table(
                children: [
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          'Stake',
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          'Delegated Stake',
                          style: Theme.of(context).textTheme.caption,
                        ),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          NumberFormat().format(peer.stake),
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          NumberFormat().format(peer.delegatedStake),
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      )
                    ],
                  )
                ],
              ),
              onTap: () {
                nav.pushStakingPeer(context, peer: peer);
              },
            );
          },
        ).toList();

        return AnimatedListView(
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
