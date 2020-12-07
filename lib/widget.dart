import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';

import 'model.dart';
import 'convex.dart' as convex;
import 'format.dart';
import 'nav.dart' as nav;

class StatelessWidgetBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const StatelessWidgetBuilder(
    this.builder, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}

Widget identicon(
  String bytes, {
  double width,
  double height,
}) =>
    SvgPicture.string(
      Jdenticon.toSvg(bytes),
      width: width,
      height: height,
    );

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

/// Returns a Fungible Token renderer Widget.
Widget fungibleTokenRenderer({
  @required convex.FungibleToken fungible,
  @required Future<int> balance,
  void Function(convex.FungibleToken) onTap,
}) =>
    StatelessWidgetBuilder((context) => Card(
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
                    builder: (context, snapshot) => snapshot.connectionState ==
                            ConnectionState.waiting
                        ? SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            snapshot.data != null
                                ? formatFungibleCurrency(
                                    metadata: fungible.metadata,
                                    number: snapshot.data,
                                  )
                                : '-',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                  )
                ],
              ),
            ),
            onTap: () {
              if (onTap != null) {
                onTap(fungible);
              }
            },
          ),
        ));

/// Returns a Non-Fungible Token renderer Widget.
Widget nonFungibleTokenRenderer() =>
    StatelessWidgetBuilder((context) => Text('Non Fungible Token'));

class AssetsCollection extends StatefulWidget {
  final Set<AAsset> assets;

  const AssetsCollection({Key key, @required this.assets}) : super(key: key);

  @override
  _AssetsCollectionState createState() => _AssetsCollectionState();
}

class _AssetsCollectionState extends State<AssetsCollection> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: widget.assets.map((aasset) {
        if (aasset.type == AssetType.fungible) {
          return fungibleTokenRenderer(
            fungible: aasset.asset as convex.FungibleToken,
            balance: appState.fungibleClient().balance(
                  token: aasset.asset.address,
                  holder: appState.model.activeAddress,
                ),
            onTap: (fungible) {
              // This seems a little bit odd, but once the route pops,
              // we call `setState` to ask Flutter to rebuild this Widget,
              // which will then create new Future objects
              // for each Token & balance.
              nav
                  .pushAsset(
                    context,
                    AAsset(
                      type: AssetType.fungible,
                      asset: fungible,
                    ),
                  )
                  .then((value) => setState(() {}));
            },
          );
        }

        return nonFungibleTokenRenderer();
      }).toList(),
    );
  }
}

/// Interface to select an Account.
///
/// Note: This Widget must be used with a ModalBottomSheet builder.
class SelectAccountModal extends StatefulWidget {
  @override
  _SelectAccountModalState createState() => _SelectAccountModalState();
}

class _SelectAccountModalState extends State<SelectAccountModal> {
  String _addressHex;

  @override
  Widget build(BuildContext context) {
    var activities = context.watch<AppState>().model.activities;

    return Container(
      padding: EdgeInsets.all(12),
      child: ListView.separated(
        itemCount: activities.length + 2,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 80,
                ),
                TextButton(
                  child: Text('Scan QR Code'),
                  onPressed: () {},
                ),
              ],
            );
          } else if (index == 1) {
            return Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    helperText: 'Input the Address of the destination Account.',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _addressHex = value;
                    });
                  },
                ),
                Gap(10),
                ElevatedButton(
                  child: Text('Use Address'),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      convex.Address(
                        hex: convex.Address.trim0x(_addressHex),
                      ),
                    );
                  },
                )
              ],
            );
          } else {
            var activity =
                activities[index - 2].payload as FungibleTransferActivity;

            return ListTile(
              leading: identicon(
                activity.to.hex,
                width: 40,
                height: 40,
              ),
              title: Text('${activity.to.hex}'),
              onTap: () {
                Navigator.pop(
                  context,
                  activity.to,
                );
              },
            );
          }
        },
      ),
    );
  }
}
