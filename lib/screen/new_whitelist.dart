import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:convex_wallet/nav.dart' as nav;
import 'package:provider/provider.dart';

class AddWhitelistScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add to Whitelist'),
      ),
      body: NewWhitelistScreenBody(),
    );
  }
}

class NewWhitelistScreenBody extends StatefulWidget {
  @override
  _WhitelistScreenBodyState createState() => _WhitelistScreenBodyState();
}

class _WhitelistScreenBodyState extends State<NewWhitelistScreenBody> {
  final _formKey = GlobalKey<FormState>();
  final _addressTextController = TextEditingController();

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
              readOnly: true,
              controller: _addressTextController,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
              onTap: () {
                final params = SelectAccountParams(
                  title: 'Add Whitelist',
                  isRecentsVisible: true,
                  isContactsVisible: true,
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
                if (_formKey.currentState.validate()) {
                  context.read<AppState>().addWhitelist(
                        Address.fromHex(_address.toString()),
                        isPersistent: true,
                      );
                  Navigator.pop(context);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressTextController.dispose();
    super.dispose();
  }
}
