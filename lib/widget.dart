import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'convex.dart' as convex;
import 'format.dart';

class Identicon extends StatelessWidget {
  final KeyPair keyPair;

  const Identicon({Key key, @required this.keyPair}) : super(key: key);

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        Jdenticon.toSvg(Sodium.bin2hex(keyPair.pk)),
        fit: BoxFit.contain,
      );
}

class Identicon2 extends StatelessWidget {
  final convex.Address address;
  final bool isAddressVisible;
  final int size;

  const Identicon2({
    Key key,
    @required this.address,
    this.isAddressVisible = false,
    this.size = 64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.string(
            Jdenticon.toSvg(address.hex, size: size),
            fit: BoxFit.contain,
          ),
          if (isAddressVisible)
            Text(
              address.hex.substring(0, 15) + '...',
            ),
        ],
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
  final AAsset aasset;
  final void Function(AAsset) onTap;

  const AAssetRenderer({
    Key key,
    @required this.aasset,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (aasset.type == AssetType.fungible) {
      return FungibleTokenRenderer(
        aasset: aasset,
        onTap: onTap,
      );
    }

    return null;
  }
}

class FungibleTokenRenderer extends StatefulWidget {
  final AAsset aasset;
  final void Function(AAsset) onTap;

  const FungibleTokenRenderer({
    Key key,
    @required this.aasset,
    this.onTap,
  }) : super(key: key);

  @override
  _FungibleTokenRendererState createState() => _FungibleTokenRendererState();
}

class _FungibleTokenRendererState extends State<FungibleTokenRenderer> {
  Future<int> balance;

  @override
  void initState() {
    super.initState();

    var token = widget.aasset.asset as convex.FungibleToken;

    var appState = context.read<AppState>();

    // Check the user's balance for this Token.
    balance = appState.fungibleClient().balance(
          token: token.address,
          holder: appState.model.activeAddress,
        );
  }

  @override
  Widget build(BuildContext context) {
    var fungible = widget.aasset.asset as convex.FungibleToken;

    return Card(
      child: InkWell(
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.attach_money,
                size: 40,
                color: Colors.orangeAccent,
              ),
              Gap(10),
              Text(
                fungible.metadata.symbol,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption,
              ),
              Gap(4),
              Text(
                fungible.metadata.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText1,
              ),
              Gap(10),
              Text(
                'Balance',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption,
              ),
              Gap(4),
              FutureBuilder(
                future: balance,
                builder: (context, snapshot) =>
                    snapshot.connectionState == ConnectionState.waiting
                        ? SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            formatFungibleCurrency(
                              metadata: fungible.metadata,
                              number: snapshot.data,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
              )
            ],
          ),
        ),
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap(widget.aasset);
          }
        },
      ),
    );
  }
}
