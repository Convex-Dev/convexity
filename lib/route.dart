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
import 'screen/top_tokens.dart';

const String DEV = '/dev';
const String LAUNCHER = '/launcher';
const String HOME = '/home';
const String WALLET = '/wallet';
const String ACCOUNT = '/account';
const String TRANSFER = '/transfer';
const String SETTINGS = '/settings';
const String ASSETS = '/assets';
const String ASSET = '/asset';
const String FOLLOW = '/follow';
const String FUNGIBLE_TRANSFER = '/fungibleTransfer';
const String MY_TOKENS = '/myTokens';
const String NEW_TOKEN = '/newToken';
const String NEW_NON_FUNGIBLE_TOKEN = '/newNonFungibleToken';
const String ADDRESS_BOOK = '/addressBook';
const String WHITELIST = '/whitelist';
const String ADD_WHITELIST = '/addWhitelist';
const String NEW_CONTACT = '/newContact';
const String SELECT_ACCOUNT = '/selectAccount';
const String NON_FUNGIBLE_TOKEN = '/nonFungibleToken';
const String NON_FUNGIBLE_TRANSFER = '/nonFungibleTransfer';
const String NON_FUNGIBLE_SELL = '/nonFungibleSell';
const String ACTIVITY = '/activity';
const String STAKING = '/staking';
const String STAKING_PEER = '/stakingPeer';
const String EXCHANGE = '/exchange';
const String SELECT_FUNGIBLE = '/selectFungigle';
const String TOP_TOKENS = '/topTokens';

Map<String, WidgetBuilder> routes() => {
      DEV: (context) => DevScreen(),
      LAUNCHER: (context) => LauncherScreen(),
      HOME: (context) => HomeScreen(),
      WALLET: (context) => WalletScreen(),
      ACCOUNT: (context) => AccountScreen(),
      TRANSFER: (context) => TransferScreen(),
      SETTINGS: (context) => SettingsScreen(),
      ASSETS: (context) => AssetsScreen(),
      ASSET: (context) => AssetScreen(),
      FOLLOW: (context) => FollowAssetScreen(),
      FUNGIBLE_TRANSFER: (context) => FungibleTransferScreen(),
      MY_TOKENS: (context) => MyTokensScreen(),
      NEW_TOKEN: (context) => NewTokenScreen(),
      NEW_NON_FUNGIBLE_TOKEN: (context) => NewNonFungibleTokenScreen(),
      ADDRESS_BOOK: (context) => AddressBookScreen(),
      NEW_CONTACT: (context) => NewContactScreen(),
      SELECT_ACCOUNT: (context) => selectAccountScreen(),
      NON_FUNGIBLE_TOKEN: (context) => NonFungibleTokenScreen(),
      NON_FUNGIBLE_TRANSFER: (context) => NonFungibleTransferScreen(),
      ACTIVITY: (context) => ActivityScreen(),
      STAKING: (context) => StakingScreen(),
      STAKING_PEER: (context) => StakingPeerScreen(),
      EXCHANGE: (context) => ExchangeScreen2(),
      SELECT_FUNGIBLE: (context) => SelectFungibleScreen(),
      TOP_TOKENS: (context) => TopTokensScreen(),
    };
