import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:convex_wallet/model.dart';
import 'package:convex_wallet/nav.dart' as nav;

class WhiteListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Whitelist'),
      ),
      body: WhiteListScreenBody(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => nav.pushNewContact(context),
      ),
    );
  }
}

class WhiteListScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<AppState>().model;

    final whitelists = model.whitelists.toList(growable: false);

    if (whitelists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_list,
              size: 80,
              color: Colors.black12,
            ),
            Gap(20),
            Text(
              'Your Whitelist is empty',
              style: TextStyle(color: Colors.black45, fontSize: 16),
            )
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: whitelists.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: aidenticon(whitelists[index].item2),
            title: Text(whitelists[index].item1),
            subtitle: Text(whitelists[index].item2.toString()),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
