import 'package:flutter/material.dart';

import 'screen/launcher.dart';
import 'screen/home.dart';
import 'screen/wallet.dart';
import 'screen/account.dart';
import 'screen/settings.dart';
import 'screen/assets.dart';
import 'screen/asset.dart';
import 'screen/follow.dart';
import 'screen/transfer.dart';
import 'screen/dev.dart';
import 'screen/fungible_transfer.dart';
import 'screen/my_tokens.dart';
import 'screen/new_token.dart';
import 'screen/address_book.dart';
import 'screen/new_contact.dart';

const String dev = '/dev';
const String launcher = '/launcher';
const String home = '/home';
const String wallet = '/wallet';
const String account = '/account';
const String transfer = '/transfer';
const String settings = '/settings';
const String assets = '/assets';
const String asset = '/asset';
const String follow = '/follow';
const String fungibleTransfer = '/fungibleTransfer';
const String myTokens = '/myTokens';
const String newToken = '/newToken';
const String addressBook = '/addressBook';
const String newContact = '/newContact';

Map<String, WidgetBuilder> routes() => {
      dev: (context) => DevScreen(),
      launcher: (context) => LauncherScreen(),
      home: (context) => HomeScreen(),
      wallet: (context) => WalletScreen(),
      account: (context) => AccountScreen(),
      transfer: (context) => TransferScreen(),
      settings: (context) => SettingsScreen(),
      assets: (context) => AssetsScreen(),
      asset: (context) => AssetScreen(),
      follow: (context) => FollowAssetScreen(),
      fungibleTransfer: (context) => FungibleTransferScreen(),
      myTokens: (context) => MyTokensScreen(),
      newToken: (context) => NewTokenScreen(),
      addressBook: (context) => AddressBookScreen(),
      newContact: (context) => NewContactScreen(),
    };
