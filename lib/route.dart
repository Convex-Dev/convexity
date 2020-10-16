import 'package:flutter/material.dart';

import 'screen/home.dart';
import 'screen/wallet.dart';

const String home = '/';
const String wallet = '/wallet';

Map<String, WidgetBuilder> routes() => {
      home: (context) => HomeScreen(),
      wallet: (context) => WalletScreen(),
    };
