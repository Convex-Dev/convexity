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
  bool _isPending = false;
  int _supply = 0;

  @override
  Widget build(BuildContext context) {
    if (_isPending) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        ListTile(
          title: TextFormField(
            autofocus: true,
            onChanged: (value) {
              setState(() {
                _supply = int.tryParse(value) ?? 0;
              });
            },
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
              createSocialCurrency(context, supply: _supply);
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
        _isPending = true;
      });

      final appState = context.read<AppState>();

      Result result =
          await appState.fungibleLibrary().createToken(supply: supply);

      if (result.errorCode == null) {
        Address socialCurrencyAddress = Address(result.value);

        var metadata = FungibleTokenMetadata(
          name: 'Mike Anderson Social Currency',
          description: '',
          tickerSymbol: 'SC'+socialCurrencyAddress.value.toString(),
          currencySymbol: '',
          decimals: 0,
        );

        var fungible = FungibleToken(
          address: socialCurrencyAddress,
          metadata: metadata,
        );

        var aasset = AAsset(
          type: AssetType.fungible,
          asset: fungible,
        );

        await appState.convexityClient().requestToRegister(aasset: aasset);

        appState.setSocialCurrency(
          address: socialCurrencyAddress,
          owner: appState.model.activeAddress,
        );
      }
    } finally {
      Navigator.of(context).pop();
    }
  }
}
