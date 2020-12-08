import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return ListView.builder(
      itemBuilder: (context, index) {},
    );
  }
}
