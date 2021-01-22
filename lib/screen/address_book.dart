import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import '../widget.dart';

class AddressBookScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Address Book')),
      body: Container(
        padding: defaultScreenPadding,
        child: AddressBookScreenBody(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => nav.pushNewContact(context),
      ),
    );
  }
}

class AddressBookScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<AppState>().model;

    final contacts = model.contacts.toList(growable: false);

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts,
              size: 80,
              color: Colors.black12,
            ),
            Gap(20),
            Text(
              'Your Address Book is empty',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) => Card(
        child: Column(
          children: [
            AddressTile(
              address: contacts[index].address,
              onTap: () {
                nav.pushAccount(context, contacts[index].address);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text('EDIT'),
                  onPressed: () {
                    _edit(context, contact: contacts[index]);
                  },
                ),
                TextButton(
                  child: Text('REMOVE'),
                  onPressed: () {
                    _remove(context, contact: contacts[index]);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, {Contact contact}) async {
    var _name = await showModalBottomSheet(
      context: context,
      builder: (context) => _Edit(contact: contact),
    );

    if (_name != null) {
      final appState = context.read<AppState>();

      // 'add' will replace the existing Contact.
      appState.addContact(
        Contact(
          name: _name,
          address: contact.address,
        ),
      );
    }
  }

  void _remove(BuildContext context, {Contact contact}) async {
    var confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) => _Remove(contact: contact),
    );

    if (confirmation == true) {
      context.read<AppState>().removeContact(contact);
    }
  }
}

class _Edit extends StatefulWidget {
  final Contact contact;

  const _Edit({Key key, this.contact}) : super(key: key);

  @override
  _EditState createState() => _EditState();
}

class _EditState extends State<_Edit> {
  final formKey = GlobalKey<FormState>();

  TextEditingController nameTextController;

  @override
  void initState() {
    super.initState();

    nameTextController = TextEditingController.fromValue(
      TextEditingValue(
        text: widget.contact.name,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: widget.contact.name.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Edit Contact',
                  style: Theme.of(context).textTheme.headline6,
                ),
                Gap(20),
                aidenticon(widget.contact.address, width: 80, height: 80),
                Gap(5),
                Text(
                  widget.contact.address.toString(),
                  style: Theme.of(context).textTheme.caption,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(5),
                TextFormField(
                  autofocus: true,
                  controller: nameTextController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),
                Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlineButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                    ),
                    Gap(10),
                    ElevatedButton(
                      child: const Text('Confirm'),
                      onPressed: () {
                        if (formKey.currentState.validate()) {
                          Navigator.pop(context, nameTextController.text);
                        }
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Remove extends StatefulWidget {
  final Contact contact;

  const _Remove({Key key, this.contact}) : super(key: key);

  @override
  _RemoveState createState() => _RemoveState();
}

class _RemoveState extends State<_Remove> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Remove ${widget.contact.name}?',
                style: Theme.of(context).textTheme.headline6,
              ),
              Gap(20),
              aidenticon(widget.contact.address, width: 80, height: 80),
              Gap(5),
              Text(
                widget.contact.address.toString(),
                style: Theme.of(context).textTheme.caption,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlineButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  Gap(10),
                  ElevatedButton(
                    child: const Text('Confirm'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
