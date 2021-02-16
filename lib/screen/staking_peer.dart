import 'package:charts_flutter/flutter.dart' as charts;
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

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

  @override
  void initState() {
    super.initState();

    final appState = context.read<AppState>();
    _account = appState
        .convexClient()
        .account2(address: appState.model.activeAddress2);
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
            widget.peer.stakes[appState.model.activeAddress2] ?? 0,
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
                          widget.peer.stakes[appState.model.activeAddress2] ??
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
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _TransactStake(
                    peer: widget.peer,
                    account: _account,
                  ),
                );
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

class _TransactStake extends StatefulWidget {
  final Peer peer;
  final Future<Account> account;

  const _TransactStake({
    Key key,
    this.peer,
    this.account,
  }) : super(key: key);

  @override
  _TransactStakeState createState() => _TransactStakeState();
}

class _TransactStakeState extends State<_TransactStake> {
  // Stake amount.
  num amount;

  // Flag to indicate the app is processing the transaction.
  bool isProcessing = false;

  // Returned value from the transaction - it's used to check if the was an error.
  Result transaction;

  Widget _successLayout() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Successfully staked ${NumberFormat().format(amount ?? 0)}.',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          ElevatedButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      );

  Widget _errorLayout() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${transaction?.value}',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          ElevatedButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      );

  Widget _processingLayout() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          Gap(20),
          Text(
            'Processing...',
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ],
      );

  Widget _promptLayout() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'How much would you like to stake?',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Gap(10),
          FutureBuilder<Account>(
            future: widget.account,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
                    style: TextStyle(fontWeight: FontWeight.bold),
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
              setState(() {
                amount = int.tryParse(value);
              });
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
                onPressed: amount != null
                    ? () {
                        _transact().then((result) {
                          setState(() {
                            transaction = result;
                          });
                        });
                      }
                    : null,
              ),
            ],
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    var child;

    if (isProcessing) {
      child = _processingLayout();
    } else if (transaction != null && transaction.errorCode != null) {
      child = _errorLayout();
    } else if (transaction != null) {
      child = _successLayout();
    } else {
      child = _promptLayout();
    }

    return Container(
      padding: defaultScreenPadding,
      child: child,
    );
  }

  Future<Result> _transact() async {
    try {
      setState(() {
        isProcessing = true;
      });

      final appState = context.read<AppState>();

      return await appState.convexClient().prepareTransact(
            address: appState.model.activeAddress2,
            accountKey: appState.model.activeAccountKey,
            secretKey: appState.model.activeKeypair2.sk,
            source: '(stake ${widget.peer.address} $amount)',
          );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }
}
