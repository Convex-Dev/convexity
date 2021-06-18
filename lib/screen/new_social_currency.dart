import 'package:flutter/material.dart';

class NewSocialCurrencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Social Currency'),
      ),
      body: NewSocialCurrencyScreenBody(),
    );
  }
}

class NewSocialCurrencyScreenBody extends StatefulWidget {
  const NewSocialCurrencyScreenBody({Key? key}) : super(key: key);

  @override
  _NewSocialCurrencyScreenBodyState createState() =>
      _NewSocialCurrencyScreenBodyState();
}

class _NewSocialCurrencyScreenBodyState
    extends State<NewSocialCurrencyScreenBody> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
