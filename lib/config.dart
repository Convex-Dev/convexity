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

var convexityAddress =
    '33391329CBf87B84EdD482B04D7De6A7bC33Bb99B384D9d77B0365BD7a7e2562';
