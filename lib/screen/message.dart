import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../model.dart';
import '../widget.dart';
import '../inbox.dart' as inbox;
import 'package:provider/provider.dart';

import 'components.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = ModalRoute.of(context)!.settings.arguments as inbox.Message;

    final appState = context.watch<AppState>();
    Future<Account> account = appState.convexClient.accountDetails();

    GridView buttons = GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        childAspectRatio: 5.0,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.all(20),
        children: [
          Components.button("Accept", onPressed: () {
            accept(context);
            // Navigator.pop(context, true);
          }),
          Components.button("Decline", onPressed: () {})
        ]);

    return Scaffold(
      appBar: AppBar(title: Text(message.subject)),
      body: Container(
        padding: defaultScreenPadding,
        child: Column(
          children: [
            //Text("From",style: Theme.of(context).textTheme.headline6),
            AccountCard(
                address: message.from, account: account, showDetails: false),
            //Text(
            //  message.from.toString(),
            //),
            Divider(),
            //Text(message.subject,style: Theme.of(context).textTheme.subtitle2,
            Gap(20),
            Text(message.text),
            Divider(),
            Text("Tokens Offered",style: Theme.of(context).textTheme.headline6),
            if (message.amount != null) Text(message.amount!.toString()),
            Spacer(),
            buttons
          ],
        ),
      ),
    );
  }

  void accept(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.help,
                size: 80,
                color: Colors.black12,
              ),
              Gap(10),
              Text("Press Confirm to accept this proposal"),
              Gap(10),
              ElevatedButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
