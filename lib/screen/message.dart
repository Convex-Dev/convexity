import 'package:flutter/material.dart';

import '../widget.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Message')),
      body: Container(
        padding: defaultScreenPadding,
        child: Container(),
      ),
    );
  }
}
