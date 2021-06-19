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

    Address? socialCurrency = appState.model.socialCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text('Social Currency'),
      ),
      body: Column(
        children: [
          image(),
          Text('Mike Anderson', style: Theme.of(context).textTheme.headline4),
          Text('Digital Artist', style: Theme.of(context).textTheme.headline5),
          socialCurrency != null
              ? buildDetails(context, socialCurrency)
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

  Widget buildDetails(BuildContext context, Address socialCurrency) {
    final appState = context.watch<AppState>();
    final convexityClient = appState.convexityClient();
    final convexClient = appState.convexClient();

    List<Future> futures = [];

    futures.addAll([
      convexityClient.asset(appState.model.socialCurrency!),
      convexClient.query(source: "*address*"),
    ]);

    return FutureBuilder<List>(
      future: Future.wait(futures),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        FungibleToken? fungible = snapshot.data?.first?.asset as FungibleToken?;

        print(snapshot.data?.last.toString());

        return Column(children: [
          Text(fungible.toString()),
          ElevatedButton(
            child: Text('TRANSFER'),
            onPressed: () {
              nav.pushFungibleTransfer(
                context,
                fungible,
                appState.convexClient().balance(socialCurrency),
              );
            },
          )]);
      },
    );
  }

  Widget image() {
    return Image.asset('assets/mike.png', width: 160);
  }
}
