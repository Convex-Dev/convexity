import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:barcode_scan/barcode_scan.dart';

import '../convex.dart';
import '../logger.dart';
import '../model.dart';
import '../nav.dart';
import '../widget.dart';
import '../route.dart' as route;
import '../convex.dart' as convex;

class TransferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transfer')),
      body: Container(
        padding: defaultScreenPadding,
        child: TransferScreenBody(),
      ),
    );
  }
}

class TransferScreenBody extends StatefulWidget {
  @override
  _TransferScreenBodyState createState() => _TransferScreenBodyState();
}

class _TransferScreenBodyState extends State<TransferScreenBody> {
  var formKey = GlobalKey<FormState>();

  var fromController = TextEditingController();
  var targetController = TextEditingController();
  var amountController = TextEditingController();

  void scan() async {
    var result = await BarcodeScanner.scan();

    setState(() {
      targetController.text = result.rawContent;
    });
  }

  void transfer({
    BuildContext context,
    convex.Address to,
    int amount,
  }) async {
    final appState = context.read<AppState>();

    final contact = appState.model.contacts.firstWhere(
      (contact) => contact.address == to,
      orElse: () => null,
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
                      'Transfer $amount to ',
                    ),
                    if (contact == null)
                      Identicon2(
                        address: to,
                        isAddressVisible: true,
                        size: 30,
                      )
                    else
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

    final transferInProgress = appState.convexClient().transact(
          caller: appState.model.activeAddress,
          callerSecretKey: appState.model.activeKeyPair.sk,
          source: '(transfer 0x${to.hex} $amount)',
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
                    'Transfer returned an error: ${snapshot.data.errorCode} ${snapshot.data.value}',
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
                            'Transfered $amount to ',
                          ),
                          if (contact == null)
                            Identicon2(
                              address: to,
                              isAddressVisible: true,
                              size: 30,
                            )
                          else
                            Text(contact.name + '.'),
                        ],
                      ),
                    ),
                    Gap(10),
                    ElevatedButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.popUntil(
                          context,
                          ModalRoute.withName(route.launcher),
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

    fromController.text = appState.model.activeAddress.toString();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextField(
              readOnly: true,
              autofocus: false,
              controller: fromController,
              decoration: InputDecoration(
                labelText: 'From',
              ),
            ),
            TextFormField(
              readOnly: true,
              autofocus: false,
              controller: targetController,
              decoration: InputDecoration(
                labelText: 'To',
                hintText: 'Address of payee',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the address.';
                }

                return null;
              },
              onTap: () {
                pushSelectAccount(context).then((selectedAddress) {
                  if (selectedAddress != null) {
                    setState(() {
                      targetController.text = selectedAddress.toString();
                    });
                  }
                });
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              controller: amountController,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Amount in Convex Coins',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the amount.';
                }

                if (int.tryParse(value) == null) {
                  return 'Please enter the amount as number.';
                }

                return null;
              },
            ),
            Gap(20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text('Transfer'),
                onPressed: () {
                  if (formKey.currentState.validate()) {
                    transfer(
                      context: context,
                      to: convex.Address.fromHex(targetController.text),
                      amount: int.parse(amountController.text),
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    fromController.dispose();
    targetController.dispose();
    amountController.dispose();

    super.dispose();
  }
}
