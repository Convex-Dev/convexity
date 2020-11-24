import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'wallet.dart' as wallet;

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

        context.read<AppState>().setActiveKeyPair(selectedKeyPair);

        wallet.setActiveKeyPair(selectedKeyPair);
      },
    );
  }
}

class AssetMetadataRenderer extends StatelessWidget {
  final AssetMetadata metadata;
  final void Function(AssetMetadata) onTap;

  const AssetMetadataRenderer({
    Key key,
    @required this.metadata,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (metadata is FungibleTokenMetadata) {
      return FungibleTokenRenderer(
        metadata: metadata,
        onTap: onTap,
      );
    }

    return NonFungibleTokenRenderer(
      metadata: metadata,
      onTap: onTap,
    );
  }
}

class FungibleTokenRenderer extends StatelessWidget {
  final FungibleTokenMetadata metadata;
  final void Function(AssetMetadata) onTap;

  const FungibleTokenRenderer({
    Key key,
    @required this.metadata,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flag(symbolToCountryCode(metadata.symbol), height: 20),
              Gap(10),
              Text(
                metadata.symbol,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption,
              ),
              Gap(10),
              Text(
                metadata.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap(metadata);
        }
      },
    );
  }
}

class NonFungibleTokenRenderer extends StatelessWidget {
  final NonFungibleTokenMetadata metadata;
  final void Function(AssetMetadata) onTap;

  const NonFungibleTokenRenderer({
    Key key,
    @required this.metadata,
    this.onTap,
  }) : super(key: key);

  Widget tokenIdenticon() => SvgPicture.string(
        Jdenticon.toSvg('A'),
        width: 30,
        height: 30,
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(metadata.name),
            Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                tokenIdenticon(),
                tokenIdenticon(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
