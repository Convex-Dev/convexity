import 'package:flutter/cupertino.dart';
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
        subject: "Commission from Alice",
        from: convex.Address(2229),
        text: "I'd like two hours of your time to create a new Logo icon for my website!",
        amount: 120,
      ),
      inbox.Message(
        subject: "Commission from Bob",
        from: convex.Address(2231),
        text: "Looking to create a batch of 10 new pixel art NFTs. Can you help?"
      ),
    ];

    final widgets = messages
        .map(
          (message) => ListTile(
            contentPadding: EdgeInsets.all(10),
            leading: Icon(Icons.markunread_rounded),
            title: Text(message.subject),
            subtitle: Text(message.text),
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
