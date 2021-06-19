import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widget.dart';
import '../model.dart';
import '../nav.dart' as nav;

class SocialCurrencyScreen extends StatelessWidget {
  const SocialCurrencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final convexityClient = appState.convexityClient();
    final convexClient = appState.convexClient();

    List<Future> futures = [];

    if (appState.model.socialCurrency != null) {
      futures.addAll([
        convexityClient.asset(appState.model.socialCurrency!),
        convexClient.query(source: "*address*"),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Social Currency'),
      ),
      body: Column(
        children: [
          appState.model.socialCurrency != null
              ? Column(
                  children: [
                    image(),
                    Text('Mike Anderson',
                        style: Theme.of(context).textTheme.headline4),
                    Text('Digital Artist',
                        style: Theme.of(context).textTheme.headline5),
                    FutureBuilder<List>(
                      future: Future.wait(futures),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        FungibleToken? fungible =
                            snapshot.data?.first?.asset as FungibleToken?;

                        print(snapshot.data?.last.toString());

                        // nav.pushFungibleTransfer(
                        //   context,
                        //   fungible,
                        //   appState
                        //       .convexClient()
                        //       .balance(appState.model.socialCurrency),
                        // );

                        return Text(fungible.toString());
                      },
                    ),
                    Center(
                        child: Text(appState.model.socialCurrency.toString())),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Create your own Personal Currency.'),
                    Center(
                      child: ElevatedButton(
                        child: const Text('Create Social Currency'),
                        onPressed: () {
                          nav.pushNewSocialCurrency(context);
                        },
                      ),
                    )
                  ],
                )
        ],
      ),
    );
  }

  Widget image() {
    return Image.asset('assets/mike.png', width: 160);
  }
}
