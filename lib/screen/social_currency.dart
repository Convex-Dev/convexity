import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../nav.dart' as nav;
import "components.dart";

class SocialCurrencyScreen extends StatelessWidget {
  const SocialCurrencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    Address? socialCurrency = appState.model.socialCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text('Social Token'),
      ),
      body: Column(
        children: [
          Gap(30),
          image(),
          Text('Mike Anderson', style: Theme.of(context).textTheme.headline4),
          Text('Digital Artist', style: Theme.of(context).textTheme.headline5),
          Gap(30),
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
      convexClient.query(source: '(let [sc #${socialCurrency.value}]'
          '[sc/supply '
          '(call sc (balance *address*))])'),
    ]);

    return FutureBuilder<List>(
      future: Future.wait(futures),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        List data=snapshot.data!;
        FungibleToken? fungible = data.first?.asset as FungibleToken?;
        List resultList=(data.elementAt(1) as Result).value as List;

        print(snapshot.data?.last.toString());
        String? symbol = fungible?.metadata.tickerSymbol;
        String? description = fungible?.metadata.description;
        GridView tab = GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 8.0,
            padding: EdgeInsets.all(20),
            children: [
              Text("Currency Symbol"),
              Text((symbol != null) ? symbol : "not defined"),
              Text("Total Issued Supply"),
              Text(resultList[0].toString()),
              Text("Your Holding"),
              Text(resultList[1].toString())
            ]);

        GridView buttons = GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          childAspectRatio: 5.0,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          padding: EdgeInsets.all(20),
          children: [
            Components.button("Gift",
              onPressed: () {
                nav.pushFungibleTransfer(
                  context,
                  fungible,
                  appState.convexClient().balance(socialCurrency),
                );
              },
            ),
            Components.button("Mint",
              onPressed: () {
                nav.pushFungibleTransfer(
                  context,
                  fungible,
                  appState.convexClient().balance(socialCurrency),
                );
              },
            ),
            Components.button("Edit Profile...",
              onPressed: () {
              },
            ),
            Components.button("Inbox",onPressed: () {
              nav.pushInbox(context);
            })
          ]

        );

        return Column(children: [
          Text(description != null ? description : "No description"),
          Divider(height: 20),
          SizedBox(child: tab),
          Divider(height: 20),
          buttons
        ]);
      },
    );
  }

  Widget image() {
    return Image.asset('assets/mike.png', width: 160);
  }
}
