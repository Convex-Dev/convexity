import 'package:flutter/material.dart';

class SocialCurrencyScreen extends StatelessWidget {
  const SocialCurrencyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Currency'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Create Social Currency'),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
    );
  }
}
