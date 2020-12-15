import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart' as sodium;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';
import 'route.dart' as route;
import 'preferences.dart' as p;
import 'config.dart' as config;
import 'logger.dart';

void main() {
  sodium.Sodium.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(model: Model()),
      child: App(),
    ),
  );
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  void bootstrap() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final allKeyPairs = p.allKeyPairs(preferences);
      final activeKeyPair = p.activeKeyPair(preferences);
      final following = p.readFollowing(preferences);
      final myTokens = p.readMyTokens(preferences);
      final activities = p.readActivities(preferences);
      final contacts = p.readContacts(preferences);

      logger.d(
        'BOOTSTRAP:\n'
        'Server: $convexWorldUri\n'
        'All KeyPairs: $allKeyPairs\n'
        'Active KeyPair: $activeKeyPair\n'
        'Following: $following\n'
        'My Tokens: $myTokens\n'
        'Activities: $activities\n'
        'Contacts: ${contacts.isEmpty ? 'Empty' : contacts.length}',
      );

      context.read<AppState>().setState(
            (_) => Model(
              convexServerUri: convexWorldUri,
              allKeyPairs: allKeyPairs,
              activeKeyPair: activeKeyPair,
              following: following,
              myTokens: myTokens,
              activities: activities,
              contacts: contacts,
            ),
          );
    } catch (e, s) {
      logger.e('$e $s');
    }
  }

  @override
  void initState() {
    super.initState();

    bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convexity',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: route.routes(),
      initialRoute: config.isDebug() ? route.dev : route.launcher,
    );
  }
}
