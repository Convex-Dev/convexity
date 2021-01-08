import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../nav.dart' as nav;

class FungibleTransferScreen extends StatelessWidget {
  final FungibleToken token;
  final Future balance;

  const FungibleTransferScreen({
    Key key,
    this.token,
    this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var arguments = ModalRoute.of(context).settings.arguments
        as Tuple2<FungibleToken, Future<dynamic>>;

    // Token and balance can be passed directly to the constructor,
    // or via the Navigator arguments.
    var _token = token ?? arguments.item1;
    var _balance = balance ?? arguments.item2;

    return WillPopScope(
      child: Scaffold(
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
      ),
      onWillPop: () async {
        Navigator.of(context).pop(false);

        return false;
      },
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
  final _formKey = GlobalKey<FormState>();
  final _receiverTextController = TextEditingController();
  int _amount;

  Address get _receiver => _receiverTextController.text.isNotEmpty
      ? Address.fromHex(_receiverTextController.text)
      : null;

  void send(BuildContext context) async {
    var appState = context.read<AppState>();

    final contact = appState.model.contacts.firstWhere(
      (contact) => contact.address == _receiver,
      orElse: () => null,
    );

    var formattedAmount = formatFungibleCurrency(
      metadata: widget.token.metadata,
      number: _amount,
    );

    var confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.help,
                size: 80,
                color: Colors.black12,
              ),
              Gap(10),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Transfer $formattedAmount to ',
                    ),
                    if (contact == null) ...[
                      aidenticon(
                        Address.fromHex(_receiverTextController.text),
                        width: 30,
                        height: 30,
                      ),
                      Expanded(
                        child: Text(
                          _receiverTextController.text,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      Text(contact.name),
                    Text(
                      '?',
                    )
                  ],
                ),
              ),
              Gap(10),
              ElevatedButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              )
            ],
          ),
        );
      },
    );

    if (confirmation != true) {
      return;
    }

    var transferInProgress = appState.fungibleLibrary().transfer(
          token: widget.token.address,
          holder: appState.model.activeAddress,
          holderSecretKey: appState.model.activeKeyPair.sk,
          receiver: _receiver,
          amount: _amount,
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
                if (snapshot.connectionState == ConnectionState.waiting) {
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

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.check,
                      size: 80,
                      color: Colors.green,
                    ),
                    Gap(10),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Transfered $formattedAmount to ',
                          ),
                          if (contact == null) ...[
                            aidenticon(
                              Address.fromHex(_receiverTextController.text),
                              width: 30,
                              height: 30,
                            ),
                            Expanded(
                              child: Text(
                                _receiverTextController.text,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            Text(contact.name),
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
                            to: _receiver,
                            amount: _amount,
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
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final contact = appState.model.contacts.firstWhere(
      (contact) => contact.address == _receiver,
      orElse: () => null,
    );

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _receiver == null
                ? SizedBox(
                    width: 120,
                    height: 120,
                  )
                : aidenticon(
                    _receiver,
                    height: 120,
                    width: 120,
                  ),
            _receiver == null
                ? SizedBox(
                    height: 33,
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      contact == null ? 'Not in Address Book' : contact.name,
                    ),
                  ),
            TextFormField(
              readOnly: true,
              controller: _receiverTextController,
              decoration: InputDecoration(
                labelText: 'To',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Required';
                }

                return null;
              },
              onTap: () {
                nav.pushSelectAccount(context).then((selectedAddress) {
                  if (selectedAddress != null) {
                    setState(() {
                      _receiverTextController.text = selectedAddress.toString();
                    });
                  }
                });
              },
            ),
            Gap(20),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"^\d?\.?\d{0,12}"),
                  replacementString: '',
                ),
              ],
              validator: (value) {
                if (value.isEmpty) {
                  return 'Required';
                }

                return null;
              },
              onChanged: (value) {
                final amount = num.tryParse(value) *
                    pow(10, widget.token.metadata.decimals);

                logger.d(
                  'Set amount: ${amount.toInt()} ' +
                      '(Token decimals: ${widget.token.metadata.decimals}; ' +
                      'amount = $value * 10^${widget.token.metadata.decimals})',
                );

                setState(() {
                  _amount = amount.toInt();
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
                      if (_formKey.currentState.validate()) {
                        send(context);
                      }
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void dispose() {
    _receiverTextController.dispose();

    super.dispose();
  }
}
