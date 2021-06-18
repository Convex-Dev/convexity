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
  @override
  Widget build(BuildContext context) {
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
              final appState = context.read<AppState>();

              appState.setSocialCurrency(
                address: Address(8),
                owner: appState.model.activeAddress,
              );

              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }
}
