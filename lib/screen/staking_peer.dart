import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/logger.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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
        child: StakingPeerScreenBody(
          peer: _peer,
        ),
      ),
    );
  }
}

class StakingPeerScreenBody extends StatefulWidget {
  final Peer peer;

  const StakingPeerScreenBody({Key key, this.peer}) : super(key: key);

  @override
  _StakingPeerScreenBodyState createState() => _StakingPeerScreenBodyState();
}

class _StakingPeerScreenBodyState extends State<StakingPeerScreenBody> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          defaultColumnWidth: IntrinsicColumnWidth(),
          children: [
            TableRow(
              children: [
                _cell(
                  context,
                  text: 'Stake',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.caption,
                ),
                _cell(
                  context,
                  text: 'Delegated Stake',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.caption,
                ),
                _cell(
                  context,
                  text: 'Owned Stake',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
            TableRow(
              children: [
                _cell(
                  context,
                  text: NumberFormat().format(widget.peer.stake),
                ),
                _cell(
                  context,
                  text: NumberFormat().format(widget.peer.delegatedStake),
                ),
                _cell(
                  context,
                  text: NumberFormat().format(
                      widget.peer.stakes[appState.model.activeAddress] ?? 0),
                ),
              ],
            )
          ],
        ),
        Gap(20),
        ElevatedButton(
          child: Text('Stake'),
          onPressed: () {
            final confirmation = showModalBottomSheet(
              context: context,
              builder: (context) {
                return Container(
                  padding: defaultScreenPadding,
                  height: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(),
                      Gap(20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlineButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                          ),
                          Gap(10),
                          ElevatedButton(
                            child: Text('Confirm'),
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            );

            confirmation.then((value) {
              if (value == true) {
                final appState = context.read<AppState>();

                appState.convexClient().transact(
                      caller: appState.model.activeAddress,
                      callerSecretKey: appState.model.activeKeyPair.sk,
                      source: '(stake ${widget.peer.address} 10)',
                    );
              }
            });
          },
        ),
      ],
    );
  }

  Widget _cell(
    BuildContext context, {
    String text,
    TextStyle style,
    TextAlign textAlign = TextAlign.right,
  }) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12),
        child: Text(
          text,
          textAlign: textAlign,
          style: style ?? Theme.of(context).textTheme.bodyText2,
        ),
      ),
    );
  }
}
