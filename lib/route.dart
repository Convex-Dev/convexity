import 'package:flutter/material.dart';

import 'screen/launcher.dart';
import 'screen/home.dart';
import 'screen/wallet.dart';
import 'screen/account.dart';

const String launcher = '/';
const String home = '/home';
const String wallet = '/wallet';
const String account = '/account';

Map<String, WidgetBuilder> routes() => {
      launcher: (context) => LauncherScreen(),
      home: (context) => HomeScreen(),
      wallet: (context) => WalletScreen(),
      account: (context) => AccountScreen(),
    };
