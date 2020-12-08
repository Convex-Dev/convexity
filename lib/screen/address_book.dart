import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;

class AddressBookScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Address Book')),
      body: AddressBookScreenBody(),
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

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: Icon(Icons.account_box),
            title: Text(contacts[index].name),
            subtitle: Text(contacts[index].address.toString()),
          ),
        ),
      ),
    );
  }
}
