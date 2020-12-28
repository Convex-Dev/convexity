import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model.dart';
import '../widget.dart';
import '../convex.dart' as convex;
import 'package:convex_wallet/nav.dart' as nav;

class TransferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Transfer ')],
        ),
      )),
      body: TransferScreenBody(),
    );
  }
}

class TransferScreenBody extends StatefulWidget {
  @override
  _TransferScreenBodyState createState() => _TransferScreenBodyState();
}

class _TransferScreenBodyState extends State<TransferScreenBody> {
  final _formKey = GlobalKey<FormState>();

  final _receiverTextController = TextEditingController();
  int _amount;

  convex.Address get _receiver => _receiverTextController.text.isNotEmpty
      ? convex.Address.fromHex(_receiverTextController.text)
      : null;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    final replacement = SizedBox(
      width: 120,
      height: 120,
    );

    return Form(
        child: Container(
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: _receiver != null,
            replacement: replacement,
            child: _receiver == null
                ? replacement
                : identicon(
                    _receiver.hex,
                    height: 120,
                    width: 120,
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
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value.isEmpty) {
                return 'Required';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _amount = int.tryParse(value);
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
                  onPressed: () {},
                ),
              )
            ],
          )
        ],
      ),
    ));
  }

  @override
  void dispose() {
    _receiverTextController.dispose();

    super.dispose();
  }
}
