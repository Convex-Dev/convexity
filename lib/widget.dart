import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'convex.dart' as convex;
import 'convexity.dart' as convexity;

class Identicon extends StatelessWidget {
  final KeyPair keyPair;

  const Identicon({Key key, @required this.keyPair}) : super(key: key);

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        Jdenticon.toSvg(Sodium.bin2hex(keyPair.pk)),
        fit: BoxFit.contain,
      );
}

class IdenticonDropdown extends StatelessWidget {
  final KeyPair activeKeyPair;
  final List<KeyPair> allKeyPairs;
  final double width;
  final double height;

  const IdenticonDropdown({
    Key key,
    this.activeKeyPair,
    this.allKeyPairs,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var activePK = Sodium.bin2hex(activeKeyPair.pk);

    var allPKs = allKeyPairs.map((_keyPair) => Sodium.bin2hex(_keyPair.pk));

    return DropdownButton<String>(
      value: activePK,
      items: allPKs
          .map(
            (s) => DropdownMenuItem(
              child: SvgPicture.string(
                Jdenticon.toSvg(s),
                width: width ?? 40,
                height: height ?? 40,
                fit: BoxFit.contain,
              ),
              value: s,
            ),
          )
          .toList(),
      onChanged: (_pk) {
        var selectedKeyPair = allKeyPairs
            .firstWhere((_keyPair) => _pk == Sodium.bin2hex(_keyPair.pk));

        context
            .read<AppState>()
            .setActiveKeyPair(selectedKeyPair, isPersistent: true);
      },
    );
  }
}

class AAssetRenderer extends StatelessWidget {
  final convex.Address userAddress;
  final AAsset aasset;
  final void Function(AAsset) onTap;

  const AAssetRenderer({
    Key key,
    @required this.userAddress,
    @required this.aasset,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (aasset.type == AssetType.fungible) {
      return FungibleTokenRenderer(
        userAddress: userAddress,
        aasset: aasset,
        onTap: onTap,
      );
    }

    return null;
  }
}

class FungibleTokenRenderer extends StatelessWidget {
  final convex.Address userAddress;
  final AAsset aasset;
  final void Function(AAsset) onTap;

  const FungibleTokenRenderer({
    Key key,
    @required this.userAddress,
    @required this.aasset,
    this.onTap,
  }) : super(key: key);

  String symbolToCountryCode(String symbol) {
    switch (symbol) {
      // Kuwait Dinar
      case 'KWD':
        return 'kw';
      // Bahrain Dinar
      case 'BHD':
        return 'bh';
      // Oman Rial
      case 'OMR':
        return 'om';
      // Jordan Dinar
      case 'JOD':
        return 'jo';
      // British Pound Sterling
      case 'GBP':
        return 'gb';
      // European Euro
      case 'EUR':
        return 'eu';
      // Swiss Franc
      case 'CHF':
        return 'ch';
      // US Dollar
      case 'USD':
        return 'us';
      case 'KYD':
        return 'ky';
      // Canadian Dollar
      case 'CAD':
        return 'ca';
    }

    return null;
  }

  void queryBalance(Uri convexServerUri, convex.Address address) async {
    var balance = await convexity.fungibleBalance(convexServerUri, address);

    print('Balance $balance');
  }

  @override
  Widget build(BuildContext context) {
    var token = aasset.asset as FungibleToken;

    var model = context.watch<AppState>().model;

    queryBalance(model.convexServerUri, token.address);

    return Card(
      child: InkWell(
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flag(symbolToCountryCode(token.metadata.symbol), height: 20),
              Gap(10),
              Text(
                token.metadata.symbol,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption,
              ),
              Gap(10),
              Text(
                token.metadata.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ],
          ),
        ),
        onTap: () {
          if (onTap != null) {
            onTap(aasset);
          }
        },
      ),
    );
  }
}
