import 'package:flutter/material.dart';

import '../widget.dart';

class TopTokensScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Top Tokens')),
      body: Container(
        padding: defaultScreenPadding,
        child: TopTokensScreenBody(),
      ),
    );
  }
}

class TopTokensScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
