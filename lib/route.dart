import 'package:flutter/material.dart';

import 'screen/launcher.dart';
import 'screen/home.dart';
import 'screen/wallet.dart';
import 'screen/account.dart';
import 'screen/settings.dart';
import 'screen/assets.dart';
import 'screen/follow_asset.dart';
import 'screen/transfer.dart';

const String launcher = '/';
const String home = '/home';
const String wallet = '/wallet';
const String account = '/account';
const String transfer = '/transfer';
const String settings = '/settings';
const String assets = '/assets';
const String followAsset = '/assets/follow';

Map<String, WidgetBuilder> routes() => {
      launcher: (context) => LauncherScreen(),
      home: (context) => HomeScreen(),
      wallet: (context) => WalletScreen(),
      account: (context) => AccountScreen(),
      transfer: (context) => TransferScreen(),
      settings: (context) => SettingsScreen(),
      assets: (context) => AssetsScreen(),
      followAsset: (context) => FollowAssetScreen(),
    };
