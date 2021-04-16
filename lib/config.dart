import 'package:convex_wallet/convex.dart';
import 'package:flutter/foundation.dart' as foundation;

const CONVEX_WORLD_HOST = 'convex.world';

bool isDebug() => foundation.kDebugMode;

Uri convexServerUri() => isDebug()
    ? Uri(
        scheme: 'http',
        host: 'localhost',
        port: 8080,
      )
    : Uri(
        scheme: 'https',
        host: CONVEX_WORLD_HOST,
        port: 443,
      );

// This is temporary.
const NFT_SHOP_ADDRESS = const Address(3378);
