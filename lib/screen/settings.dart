import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            child: Text('CLEAR'),
            onPressed: () {
              SharedPreferences.getInstance().then(
                (preferences) => preferences.clear(),
              );
            },
          ),
        ],
      ),
    );
  }
}
