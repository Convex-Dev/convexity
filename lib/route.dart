import 'package:flutter/material.dart';

import 'screen/exchange2.dart';
import 'widget.dart';
import 'screen/staking_peer.dart';
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
import 'screen/new_nft_token.dart';
import 'screen/address_book.dart';
import 'screen/new_contact.dart';
import 'screen/non_fungible_token.dart';
import 'screen/non_fungible_transfer.dart';
import 'screen/activity.dart';
import 'screen/staking.dart';
import 'screen/select_fungible.dart';

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
const String newNonFungibleToken = '/newNonFungibleToken';
const String addressBook = '/addressBook';
const String whitelist = '/whitelist';
const String addWhitelist = '/addWhitelist';
const String newContact = '/newContact';
const String selectAccount = '/selectAccount';
const String nonFungibleToken = '/nonFungibleToken';
const String nonFungibleTransfer = '/nonFungibleTransfer';
const String activity = '/activity';
const String staking = '/staking';
const String stakingPeer = '/stakingPeer';
const String exchange = '/exchange';
const String selectFungible = '/selectFungigle';

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
      newNonFungibleToken: (context) => NewNonFungibleTokenScreen(),
      addressBook: (context) => AddressBookScreen(),
      newContact: (context) => NewContactScreen(),
      selectAccount: (context) => selectAccountScreen(),
      nonFungibleToken: (context) => NonFungibleTokenScreen(),
      nonFungibleTransfer: (context) => NonFungibleTransferScreen(),
      activity: (context) => ActivityScreen(),
      staking: (context) => StakingScreen(),
      stakingPeer: (context) => StakingPeerScreen(),
      exchange: (context) => ExchangeScreen2(),
      selectFungible: (context) => SelectFungibleScreen(),
    };
