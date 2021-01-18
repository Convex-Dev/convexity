import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:tuple/tuple.dart';

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

    final c = [
      Tuple2<String, String>('From', a.from.toString()),
      Tuple2<String, String>('To', a.to.toString()),
    ];

    return ListView.builder(
      itemCount: c.length,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                c[index].item1,
                style: TextStyle(color: Colors.black54),
              ),
              Gap(20),
              Flexible(
                flex: 1,
                child: Row(
                  children: [
                    aidenticon(a.from, width: 30, height: 30),
                    Gap(5),
                    Expanded(
                      child: Text(
                        c[index].item2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
