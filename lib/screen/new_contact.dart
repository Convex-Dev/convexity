import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';

import '../widget.dart';

class NewContactScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Contact')),
      body: NewContactScreenBody(),
    );
  }
}

class NewContactScreenBody extends StatefulWidget {
  @override
  _NewContactScreenBodyState createState() => _NewContactScreenBodyState();
}

class _NewContactScreenBodyState extends State<NewContactScreenBody> {
  final _formKey = GlobalKey<FormState>();
  final _addressTextController = TextEditingController();

  String _alias;

  Address get _address => _addressTextController.text.isNotEmpty
      ? Address.fromHex(_addressTextController.text)
      : null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          ListTile(
            title: TextFormField(
              autofocus: true,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Required';
                }

                return null;
              },
              onChanged: (value) {
                setState(() {
                  _alias = value;
                });
              },
            ),
            subtitle: Text('Name'),
          ),
          ListTile(
            title: TextFormField(
              readOnly: true,
              controller: _addressTextController,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Required';
                }

                return null;
              },
              onTap: () {
                selectAccount(context).then((selectedAddress) {
                  if (selectedAddress != null) {
                    setState(() {
                      _addressTextController.text = selectedAddress.toString();
                    });
                  }
                });
              },
            ),
            subtitle: Text('Address'),
          ),
          Container(
            padding: EdgeInsets.all(15),
            child: ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                if (_formKey.currentState.validate()) {}
              },
            ),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _addressTextController.dispose();

    super.dispose();
  }
}
