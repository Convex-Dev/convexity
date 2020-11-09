import 'package:convex_wallet/screen/transfer.dart';
import 'package:flutter/material.dart';

import 'screen/launcher.dart';
import 'screen/home.dart';
import 'screen/wallet.dart';
import 'screen/account.dart';
import 'screen/settings.dart';

const String launcher = '/';
const String home = '/home';
const String wallet = '/wallet';
const String account = '/account';
const String transfer = '/transfer';
const String settings = '/settings';

Map<String, WidgetBuilder> routes() => {
      launcher: (context) => LauncherScreen(),
      home: (context) => HomeScreen(),
      wallet: (context) => WalletScreen(),
      account: (context) => AccountScreen(),
      transfer: (context) => TransferScreen(),
      settings: (context) => SettingsScreen(),
    };
