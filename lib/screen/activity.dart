import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widget.dart';
import '../model.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          children: [
            TableRow(
              children: [
                TableCell(
                  child: Text(
                    'From',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                TableCell(
                  child: Text(
                    'To',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                TableCell(
                  child: Text(
                    'Amount',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                TableCell(
                  child: Text(
                    a.from.toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TableCell(
                  child: Text(
                    a.to.toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TableCell(
                  child: Text(NumberFormat().format(a.amount)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
