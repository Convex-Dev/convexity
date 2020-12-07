import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../convex.dart';
import '../widget.dart';
import '../model.dart';
import '../format.dart';
import '../logger.dart';
import '../route.dart' as route;

class FungibleTransferScreen extends StatelessWidget {
  final FungibleToken token;

  const FungibleTransferScreen({Key key, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var arguments = ModalRoute.of(context).settings.arguments
        as Tuple2<FungibleToken, Future<int>>;

    // Token can be passed directly to the constructor,
    // or via the Navigator arguments.
    var _token = token ?? arguments.item1;
    var _balance = arguments.item2;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Transfer ${_token.metadata.symbol}',
              ),
              FutureBuilder(
                future: _balance,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  var formattedBalance = formatFungibleCurrency(
                    metadata: _token.metadata,
                    number: snapshot.data as int,
                  );

                  return Text(
                    'Balance $formattedBalance',
                    style: TextStyle(fontSize: 14),
                  );
                },
              )
            ],
          ),
        ),
      ),
      body: FungibleTransferScreenBody(token: _token),
    );
  }
}

class FungibleTransferScreenBody extends StatefulWidget {
  final FungibleToken token;

  const FungibleTransferScreenBody({Key key, this.token}) : super(key: key);

  @override
  _FungibleTransferScreenBodyState createState() =>
      _FungibleTransferScreenBodyState();
}

class _FungibleTransferScreenBodyState
    extends State<FungibleTransferScreenBody> {
  Address receiver;
  int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            color: Colors.black26,
            iconSize: 120,
            icon: receiver != null
                ? identicon(receiver.hex)
                : Icon(
                    Icons.account_circle_outlined,
                  ),
            onPressed: () {
              showModalBottomSheet<Address>(
                context: context,
                builder: (context) => SelectAccountModal(),
              ).then((selectedAddress) {
                setState(() {
                  receiver = selectedAddress;
                });
              });
            },
          ),
          if (receiver != null)
            Text(
              receiver.hex.substring(0, 32) + '...',
            ),
          Gap(20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Amount',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                amount = int.tryParse(value);
              });
            },
          ),
          Gap(30),
          Column(
            children: [
              Gap(20),
              SizedBox(
                height: 60,
                width: 100,
                child: ElevatedButton(
                  child: Text('SEND'),
                  onPressed: () {
                    var appState = context.read<AppState>();

                    var transferInProgress = appState.fungibleClient().transfer(
                          token: widget.token.address,
                          holder: appState.model.activeAddress,
                          holderSecretKey: appState.model.activeKeyPair.sk,
                          receiver: receiver,
                          amount: amount,
                        );

                    showModalBottomSheet(
                      context: context,
                      isDismissible: false,
                      enableDrag: false,
                      builder: (BuildContext context) {
                        return Container(
                          height: 300,
                          child: Center(
                            child: FutureBuilder(
                              future: transferInProgress,
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<Result> snapshot,
                              ) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                if (snapshot.data?.errorCode != null) {
                                  logger.e(
                                    'Fungible transfer returned an error: ${snapshot.data.errorCode} ${snapshot.data.value}',
                                  );

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.error,
                                        size: 80,
                                        color: Colors.black12,
                                      ),
                                      Gap(10),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Text(
                                          'Sorry. Your transfer could not be completed.',
                                        ),
                                      ),
                                      Gap(10),
                                      ElevatedButton(
                                        child: const Text('Okay'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      )
                                    ],
                                  );
                                }

                                var formattedAmount = formatFungibleCurrency(
                                  metadata: widget.token.metadata,
                                  number: amount,
                                );

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.check,
                                      size: 80,
                                      color: Colors.black12,
                                    ),
                                    Gap(10),
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Transfered $formattedAmount to ',
                                          ),
                                          Identicon2(
                                            address: receiver,
                                            isAddressVisible: true,
                                            size: 30,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Gap(10),
                                    ElevatedButton(
                                      child: const Text('Done'),
                                      onPressed: () {
                                        var appState = context.read<AppState>();

                                        var activity = Activity(
                                          type: ActivityType.transfer,
                                          payload: FungibleTransferActivity(
                                            from: appState.model.activeAddress,
                                            to: receiver,
                                            amount: amount,
                                            token: widget.token,
                                            timestamp: DateTime.now(),
                                          ),
                                        );

                                        appState.addActivity(
                                          activity,
                                          isPersistent: true,
                                        );

                                        Navigator.popUntil(
                                          context,
                                          ModalRoute.withName(route.asset),
                                        );
                                      },
                                    )
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
