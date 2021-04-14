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

// TODO
const CONVEX_GOLD_DECIMALS = 9;
const CONVEX_SILVER_DECIMALS = 6;
const CONVEX_BRONZE_DECIMALS = 3;
const CONVEX_COPPER_DECIMALS = 0;

// This is temporary.
const NFT_MARKET_ADDRESS = '#3333';
