import 'package:convex_wallet/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../model.dart';

class NonFungibleMarketScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final convexClient = appState.convexClient();

    return Scaffold(
      appBar: AppBar(title: Text('Non-Fungible Market')),
      body: Container(
        padding: defaultScreenPadding,
        child: AnimationLimiter(
          child: GridView.count(
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            crossAxisCount: 2,
            // TODO Token ID
            children: [0].asMap().entries.map(
              (entry) {
                // TODO Actor address
                final dataSource =
                    '(call #702 (get-token-data ${entry.value}))';

                final data = convexClient.query(source: dataSource);

                return AnimationConfiguration.staggeredGrid(
                  position: entry.key,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: NonFungibleGridTile(
                        tokenId: entry.value,
                        data: data,
                        onTap: () {},
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }
}
