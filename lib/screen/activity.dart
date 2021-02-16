import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

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

    final appState = context.watch<AppState>();

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: Colors.black54,
            ),
            Gap(5),
            Text(
              defaultDateTimeFormat(a.timestamp),
              style: Theme.of(context).textTheme.caption,
              textAlign: TextAlign.left,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            formatFungibleCurrency(
              metadata: a.token.metadata,
              number: a.amount,
            ),
            style: TextStyle(fontSize: 50),
          ),
        ),
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
                        icon: aidenticon2(a.from, width: 30, height: 30),
                        label: Expanded(
                          child: Text(
                            appState.findContact2(a.from)?.name ??
                                a.from.toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () {
                          nav.pushAccount2(context, a.from);
                        },
                      ),
                    ),
                    TableCell(
                      child: TextButton.icon(
                        icon: aidenticon2(a.to, width: 30, height: 30),
                        label: Expanded(
                          child: Text(
                            appState.findContact2(a.to)?.name ??
                                a.to.toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () {
                          nav.pushAccount2(context, a.to);
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
