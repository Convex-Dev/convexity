import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../model.dart';
import '../widget.dart';
import '../inbox.dart' as inbox;
import 'package:provider/provider.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = ModalRoute.of(context)!.settings.arguments as inbox.Message;

    final appState = context.watch<AppState>();
    Future<Account> account=appState.convexClient().accountDetails();

    return Scaffold(
      appBar: AppBar(title: Text(message.subject)),

      body: Container(
        padding: defaultScreenPadding,
        child: Column(
          children: [
            //Text("From",style: Theme.of(context).textTheme.headline6),
            AccountCard(address: message.from, account: account, showDetails: false),
            //Text(
            //  message.from.toString(),
            //),
            Divider(),
            //Text(message.subject,style: Theme.of(context).textTheme.subtitle2,
            Gap(20),
            Text(message.text),
            if (message.amount != null) Text(message.amount!.toString()),
          ],
        ),
      ),
    );
  }
}
