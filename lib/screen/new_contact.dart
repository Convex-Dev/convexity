import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';
import '../convex.dart';

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

  String? _name;

  Address? get _address => _addressTextController.text.isNotEmpty
      ? Address.fromStr(_addressTextController.text)
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
                if (value!.isEmpty) {
                  return 'Required';
                }

                return null;
              },
              onChanged: (value) {
                setState(() {
                  _name = value;
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
                if (value!.isEmpty) {
                  return 'Required';
                }

                return null;
              },
              onTap: () {
                final params = SelectAccountParams(
                  title: 'New Contact',
                  isRecentsVisible: true,
                  isContactsVisible: false,
                );

                nav.pushSelectAccount(context, params: params).then(
                  (selectedAddress) {
                    if (selectedAddress != null) {
                      setState(() {
                        _addressTextController.text =
                            selectedAddress.toString();
                      });
                    }
                  },
                );
              },
            ),
            subtitle: Text('Address'),
          ),
          Container(
            padding: EdgeInsets.all(15),
            child: ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<AppState>().addContact(
                        Contact(
                          name: _name,
                          address: _address,
                        ),
                        isPersistent: true,
                      );

                  Navigator.pop(context);
                }
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
