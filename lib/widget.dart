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
              address.toString().substring(0, 15) + '...',
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

abstract class _AWidget {
  Widget build(BuildContext context);
}

/// A [_AWidget] that contains data to display a heading.
class _HeadingItem implements _AWidget {
  final String heading;

  _HeadingItem(this.heading);

  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        heading,
        style: Theme.of(context).textTheme.headline5,
      ),
    );
  }
}

/// A [_AWidget] that contains data to display a [Contact].
class _ContactItem implements _AWidget {
  final Contact contact;

  _ContactItem(this.contact);

  Widget build(BuildContext context) => ListTile(
        leading: identicon(contact.address.hex),
        title: Text(contact.name),
        subtitle: Text(contact.address.toString()),
        onTap: () {
          Navigator.pop(context, contact.address);
        },
      );
}

/// A [_AWidget] that contains data to display an [Address].
class _AddressItem implements _AWidget {
  final convex.Address address;

  _AddressItem(this.address);

  Widget build(BuildContext context) => ListTile(
        leading: identicon(address.hex),
        title: Text(address.toString()),
        onTap: () {
          Navigator.pop(context, address);
        },
      );
}

/// Shows a Modal Bottom Sheet UI to select an Account.
Future<convex.Address> selectAccountModal(BuildContext context) =>
    showModalBottomSheet<convex.Address>(
      context: context,
      builder: (context) => _SelectAccount(),
    );

@immutable
class SelectAccountParams {
  final bool isContactsVisible;
  final bool isRecentsVisible;

  SelectAccountParams({
    this.isContactsVisible = true,
    this.isRecentsVisible = true,
  });
}

Widget selectAccountScreen({SelectAccountParams params}) =>
    StatelessWidgetBuilder((context) {
      SelectAccountParams _params =
          params ?? ModalRoute.of(context).settings.arguments;

      return Scaffold(
        appBar: AppBar(title: Text('Select Account')),
        body: _SelectAccount(
          params: _params ??
              SelectAccountParams(
                isContactsVisible: true,
                isRecentsVisible: true,
              ),
        ),
      );
    });

class _SelectAccount extends StatefulWidget {
  final SelectAccountParams params;

  const _SelectAccount({Key key, this.params}) : super(key: key);

  @override
  _SelectAccountState createState() => _SelectAccountState();
}

class _SelectAccountState extends State<_SelectAccount> {
  String _addressHex;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final l = <_AWidget>[];

    // Add recent activities.
    if (widget.params.isRecentsVisible &&
        appState.model.activities.isNotEmpty) {
      l.add(_HeadingItem('Recent'));

      // List of previous/recent transfers.
      // Map to Address, and then cast to a Set to remove duplicates.
      l.addAll(appState.model.activities
          .where((activity) => activity.type == ActivityType.transfer)
          .map((activity) =>
              _AddressItem((activity.payload as FungibleTransferActivity).to))
          .toSet()
          .toList()
          .take(5));
    }

    // Add contact items - if it's not empty.
    if (widget.params.isContactsVisible && appState.model.contacts.isNotEmpty) {
      l.add(_HeadingItem('Contacts'));
      l.addAll(appState.model.contacts.map((contact) => _ContactItem(contact)));
    }

    return Container(
      padding: EdgeInsets.all(12),
      child: ListView.builder(
        // '+ 2' because there are two Widgets, in the begining of the list,
        // to select the destination address - Scan QR Code and input text field.
        itemCount: l.length + 2,
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
                    final isNotEmpty = _addressHex?.isNotEmpty ?? false;

                    if (isNotEmpty) {
                      Navigator.pop(
                        context,
                        convex.Address(
                          hex: convex.Address.trim0x(_addressHex),
                        ),
                      );
                    }
                  },
                )
              ],
            );
          } else {
            final item = l[index - 2];

            return item.build(context);
          }
        },
      ),
    );
  }
}
