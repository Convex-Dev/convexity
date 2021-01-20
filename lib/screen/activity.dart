import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../widget.dart';
import '../model.dart';
import '../format.dart';
import '../nav.dart' as nav;

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var activity = ModalRoute.of(context).settings.arguments as Activity;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Activity'),
            Text(
              '${activityTypeString(activity.type)}',
              style: Theme.of(context)
                  .textTheme
                  .subtitle1
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: ActivityScreenBody(
          activity: activity,
        ),
      ),
    );
  }
}

class ActivityScreenBody extends StatelessWidget {
  final Activity activity;

  const ActivityScreenBody({
    Key key,
    @required this.activity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final a = activity.payload as FungibleTransferActivity;

    return Column(
      children: [
        Column(
          children: [
            Text(
              formatFungibleCurrency(
                metadata: a.token.metadata,
                number: a.amount,
              ),
              style: Theme.of(context).textTheme.headline3,
            ),
          ],
        ),
        Gap(10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Table(
              children: [
                TableRow(
                  children: [
                    TableCell(
                      child: Text(
                        'FROM',
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                    TableCell(
                      child: Text(
                        'TO',
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    TableCell(
                      child: TextButton.icon(
                        icon: aidenticon(a.from, width: 30, height: 30),
                        label: Expanded(
                          child: Text(
                            a.from.toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () {
                          nav.pushAccount(context, a.from);
                        },
                      ),
                    ),
                    TableCell(
                      child: TextButton.icon(
                        icon: aidenticon(a.to, width: 30, height: 30),
                        label: Expanded(
                          child: Text(
                            a.to.toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () {
                          nav.pushAccount(context, a.to);
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
