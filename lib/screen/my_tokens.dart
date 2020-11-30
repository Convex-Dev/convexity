import 'package:flutter/material.dart';

import '../nav.dart' as nav;

class MyTokensScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tokens'),
      ),
      body: MyTokensScreenBody(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => nav.pushNewToken(context),
      ),
    );
  }
}

class MyTokensScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('My Tokens'),
    );
  }
}
