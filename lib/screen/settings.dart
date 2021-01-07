import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SettingsScreenBody(),
    );
  }
}

class SettingsScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ElevatedButton(
            child: Text('Reset'),
            onPressed: () {
              context.read<AppState>().reset(context);
            },
          ),
        ],
      ),
    );
  }
}
