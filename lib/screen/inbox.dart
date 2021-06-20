import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../widget.dart';
import '../nav.dart' as nav;
import '../inbox.dart' as inbox;
import '../convex.dart' as convex;

class InboxScreen extends StatelessWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messages = [
      inbox.Message(
        subject: "Foo",
        from: convex.Address(8),
      ),
      inbox.Message(
        subject: "Bar",
        from: convex.Address(8),
      ),
    ];

    final widgets = messages
        .map(
          (message) => ListTile(
            leading: Icon(Icons.mark_email_unread),
            title: Text(message.subject),
            subtitle: Text('Subtitle'),
            onTap: () => nav.pushMessage(context, message),
          ),
        )
        .toList();

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
