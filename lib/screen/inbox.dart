import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../widget.dart';
import '../nav.dart' as nav;

class InboxScreen extends StatelessWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widgets = [
      ListTile(
        leading: Icon(Icons.mark_email_unread),
        title: Text('Unread'),
        subtitle: Text('Subtitle'),
        onTap: () => nav.pushMessage(context),
      ),
      ListTile(
        leading: Icon(Icons.mark_email_read),
        title: Text('Read'),
        subtitle: Text('Subtitle'),
        onTap: () => nav.pushMessage(context),
      ),
    ];

    final animated = widgets
        .asMap()
        .entries
        .map(
          (e) => AnimationConfiguration.staggeredList(
            position: e.key,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: e.value,
              ),
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Inbox')),
      body: Container(
        padding: defaultScreenPadding,
        child: AnimationLimiter(
          child: ListView(
            children: animated,
          ),
        ),
      ),
    );
  }
}
