import 'dart:math';

import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';

class NewSocialCurrencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Social Currency'),
      ),
      body: NewSocialCurrencyScreenBody(),
    );
  }
}

class NewSocialCurrencyScreenBody extends StatefulWidget {
  const NewSocialCurrencyScreenBody({Key? key}) : super(key: key);

  @override
  _NewSocialCurrencyScreenBodyState createState() =>
      _NewSocialCurrencyScreenBodyState();
}

class _NewSocialCurrencyScreenBodyState
    extends State<NewSocialCurrencyScreenBody> {
  bool isPending = false;

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        ListTile(
          title: TextFormField(
            autofocus: true,
            onChanged: (value) {},
          ),
          subtitle: Text('Supply'),
        ),
        ListTile(
          title: TextFormField(
            onChanged: (value) {},
          ),
          subtitle: Text('Description'),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: ElevatedButton(
            child: const Text('Confirm'),
            onPressed: () {
              createSocialCurrency(context, supply: 1000);
            },
          ),
        )
      ],
    );
  }

  createSocialCurrency(
    BuildContext context, {
    required int supply,
  }) async {
    try {
      setState(() {
        isPending = true;
      });

      final appState = context.read<AppState>();

      Result result =
          await appState.fungibleLibrary().createToken(supply: supply);

      if (result.errorCode == null) {
        appState.setSocialCurrency(
          address: Address(result.value),
          owner: appState.model.activeAddress,
        );
      }
    } finally {
      Navigator.of(context).pop();
    }
  }
}
