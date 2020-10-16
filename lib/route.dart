import 'package:flutter/material.dart';

import 'screen/home.dart';
import 'screen/wallet.dart';
import 'screen/account.dart';

const String home = '/';
const String wallet = '/wallet';
const String account = '/account';

Map<String, WidgetBuilder> routes() => {
      home: (context) => HomeScreen(),
      wallet: (context) => WalletScreen(),
      account: (context) => AccountScreen(),
    };
