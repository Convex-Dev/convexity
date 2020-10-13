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
