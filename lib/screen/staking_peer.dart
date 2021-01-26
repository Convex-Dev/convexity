import 'package:charts_flutter/flutter.dart' as charts;
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';
import 'package:intl/intl.dart';

import '../convex.dart';
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
  Future<Account> _account;

  int _stakeAmount;

  @override
  void initState() {
    super.initState();

    final appState = context.read<AppState>();
    _account =
        appState.convexClient().account(address: appState.model.activeAddress);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final series = [
      charts.Series<Tuple2<String, int>, String>(
        id: 'Staking',
        domainFn: (datum, index) => datum.item1,
        measureFn: (datum, index) => datum.item2,
        labelAccessorFn: (datum, index) => datum.item1,
        data: [
          Tuple2<String, int>(
            'Stake',
            widget.peer.stake,
          ),
          Tuple2<String, int>(
            'Delegated Stake',
            widget.peer.delegatedStake,
          ),
          Tuple2<String, int>(
            'Owned Stake',
            widget.peer.stakes[appState.model.activeAddress] ?? 0,
          ),
        ],
      ),
    ];

    return SingleChildScrollView(
      child: SafeArea(
        child: Column(
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
                          widget.peer.stakes[appState.model.activeAddress] ??
                              0),
                    ),
                  ],
                )
              ],
            ),
            Gap(20),
            Container(
              height: 300,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: charts.BarChart(
                series,
                vertical: false,
                barRendererDecorator: charts.BarLabelDecorator<String>(),
                domainAxis:
                    charts.OrdinalAxisSpec(renderSpec: charts.NoneRenderSpec()),
              ),
            ),
            Gap(40),
            ElevatedButton(
              child: Text('Stake'),
              onPressed: () {
                num amount;

                final confirmation = showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      padding: defaultScreenPadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'How much would you like to stake?',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          Gap(10),
                          FutureBuilder<Account>(
                            future: _account,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Available balance:'),
                                  Gap(5),
                                  Text(
                                    NumberFormat().format(
                                      snapshot.data.balance,
                                    ),
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  )
                                ],
                              );
                            },
                          ),
                          Gap(20),
                          TextField(
                            decoration: InputDecoration(labelText: 'Amount'),
                            autofocus: true,
                            onChanged: (value) {
                              amount = int.tryParse(value);
                            },
                          ),
                          Gap(40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlineButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.pop(context);
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
                          source: '(stake ${widget.peer.address} $amount)',
                        );
                  }
                });
              },
            ),
          ],
        ),
      ),
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
