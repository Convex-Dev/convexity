import 'package:flutter/material.dart';

class NewTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Token'),
      ),
      body: NewTokenScreenBody(),
    );
  }
}

class NewTokenScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('New Token'),
    );
  }
}
