import 'package:flutter/material.dart';

import '../widget.dart';
import '../inbox.dart' as inbox;

class MessageScreen extends StatelessWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = ModalRoute.of(context)!.settings.arguments as inbox.Message;

    return Scaffold(
      appBar: AppBar(title: Text(message.subject)),
      body: Container(
        padding: defaultScreenPadding,
        child: Column(
          children: [
            Text(
              message.from.toString(),
            )
          ],
        ),
      ),
    );
  }
}
