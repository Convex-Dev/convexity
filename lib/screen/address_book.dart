import 'package:convex_wallet/widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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
              'Your Address Book is empty.',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: identicon(contacts[index].address.hex),
            title: Text(contacts[index].name),
            subtitle: Text(contacts[index].address.toString()),
            onTap: () {
              nav.pushAccount(context, contacts[index].address);
            },
          ),
        ),
      ),
    );
  }
}
