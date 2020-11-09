import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TransferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transfer')),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Destination',
                hintText: 'Address',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the Account Address';
                }

                return null;
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Amount',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the amount';
                }

                return null;
              },
            ),
            ElevatedButton(
              child: Text('Transfer'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      content: Text('OK'),
                    ),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
