import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'convex.dart';
import 'model.dart';
import 'convex.dart' as convex;
import 'format.dart';
import 'nav.dart' as nav;

const defaultScreenPadding = EdgeInsets.all(12);

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

Widget aidenticon(
  Address2 address, {
  double width,
  double height,
}) =>
    identicon(
      address.value.toString(),
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
  final convex.Address2 address;
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
            Jdenticon.toSvg(address.value.toString(), size: size),
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
Widget fungibleTokenCard({
  @required convex.FungibleToken fungible,
  @required Future balance,
  bool isMine = false,
  void Function(convex.FungibleToken) onTap,
}) =>
    StatelessWidgetBuilder((context) {
      final container = Container(
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
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Gap(10),
            Text(
              'Own Holding',
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
      );

      return Stack(
        children: [
          Positioned.fill(
            child: Card(
              child: InkWell(
                child: isMine
                    ? ClipRect(
                        child: Banner(
                          message: "My Token",
                          color: Colors.orange,
                          location: BannerLocation.topEnd,
                          child: container,
                        ),
                      )
                    : container,
                onTap: () {
                  if (onTap != null) {
                    onTap(fungible);
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Fungible',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.overline,
            ),
          ),
        ],
      );
    });

/// Returns a Non-Fungible Token renderer Widget.
Widget nonFungibleTokenCard({
  @required convex.NonFungibleToken nonFungible,
  void Function(convex.NonFungibleToken) onTap,
}) =>
    StatelessWidgetBuilder((context) {
      final container = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videogame_asset,
            size: 40,
            color: Colors.orangeAccent,
          ),
          Gap(10),
          Text(
            nonFungible.metadata.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.caption,
          ),
          Gap(4),
          Text(
            nonFungible.metadata.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ],
      );

      return Stack(
        children: [
          Positioned.fill(
            child: Card(
              child: InkWell(
                child: container,
                onTap: () {
                  if (onTap != null) {
                    onTap(nonFungible);
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Non-Fungible',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.overline,
            ),
          ),
        ],
      );
    });

// ignore: must_be_immutable
class AssetsCollection extends StatefulWidget {
  final Set<AAsset> assets = {};
  final Map<AAsset, Future> balanceCache = {};

  String empty;

  AssetsCollection({
    Key key,
    @required assets,
    balanceCache,
    empty,
  }) : super(key: key) {
    this.empty = empty ?? 'Nothing to show';

    if (assets != null) {
      this.assets.addAll(Set.from(assets));
    }

    if (balanceCache != null) {
      this.balanceCache.addAll(Map.from(balanceCache));
    }
  }

  @override
  _AssetsCollectionState createState() => _AssetsCollectionState();
}

class _AssetsCollectionState extends State<AssetsCollection> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    if (widget.assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info,
              size: 80,
              color: Colors.black12,
            ),
            Gap(10),
            Text(
              widget.empty,
              style: TextStyle(
                color: Colors.black45,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      primary: false,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: widget.assets.map((aasset) {
        final balance = widget.balanceCache[aasset] ??
            appState.assetLibrary().balance(
                  asset: aasset.asset.address,
                  owner: appState.model.activeAddress2,
                );

        if (aasset.type == AssetType.fungible) {
          final mine = appState.model.myTokens.firstWhere(
            (myToken) => myToken.asset.address == aasset.asset.address,
            orElse: () => null,
          );

          return fungibleTokenCard(
            isMine: mine != null,
            fungible: aasset.asset as convex.FungibleToken,
            balance: balance,
            onTap: (fungible) {
              final asset = AAsset(
                type: AssetType.fungible,
                asset: fungible,
              );

              final result = nav.pushAsset(
                context,
                aasset: asset,
                balance: balance,
              );

              setState(() {
                widget.balanceCache[asset] = result;
              });
            },
          );
        }

        return nonFungibleTokenCard(
          nonFungible: aasset.asset as convex.NonFungibleToken,
          onTap: (nonFungible) {
            nav.pushAsset(
              context,
              aasset: AAsset(
                type: AssetType.nonFungible,
                asset: nonFungible,
              ),
              balance: balance,
            );
          },
        );
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
        leading: aidenticon(contact.address),
        title: Text(contact.name),
        subtitle: Text(contact.address.toString()),
        onTap: () {
          Navigator.pop(context, contact.address);
        },
      );
}

/// A [_AWidget] that contains data to display an [Address].
class _AddressItem implements _AWidget {
  final convex.Address2 address;

  _AddressItem(this.address);

  Widget build(BuildContext context) => ListTile(
        leading: aidenticon(address),
        title: Text('Not in Address Book'),
        subtitle: Text(address.toString()),
        onTap: () {
          Navigator.pop(context, address);
        },
      );
}

/// Shows a Modal Bottom Sheet UI to select an Account.
Future<convex.Address2> selectAccountModal(BuildContext context) =>
    showModalBottomSheet<convex.Address2>(
      context: context,
      builder: (context) => _SelectAccount(),
    );

@immutable
class SelectAccountParams {
  final String title;
  final bool isContactsVisible;
  final bool isRecentsVisible;

  SelectAccountParams({
    this.title = 'Select Account',
    this.isContactsVisible = true,
    this.isRecentsVisible = true,
  });
}

Widget selectAccountScreen({SelectAccountParams params}) =>
    StatelessWidgetBuilder((context) {
      SelectAccountParams _params =
          params ?? ModalRoute.of(context).settings.arguments;

      return Scaffold(
        appBar: AppBar(title: Text(_params.title)),
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
  String _addressStr;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final l = <_AWidget>[];

    // Add recent activities.
    if (widget.params.isRecentsVisible &&
        appState.model.activities.isNotEmpty) {
      // Map to Address, and then cast to a Set to remove duplicates.
      final recent = appState.model.activities
          .where((activity) => activity.type == ActivityType.transfer)
          .map((activity) => (activity.payload as FungibleTransferActivity).to)
          .toSet();

      var items = recent
          .map((to) {
            // Check if address is saved in the Address Book.
            final contact = appState.model.contacts.firstWhere(
              (contact) => contact.address == to,
              orElse: () => null,
            );

            // Replace an Address item for a Contact item
            // if address is in the Address Book.
            return contact != null ? _ContactItem(contact) : _AddressItem(to);
          })
          .toList()
          .reversed;

      // If [isContactsVisible] is true, we simply take the last 5.
      // Otherwise, we need to check and remove contacts.
      if (widget.params.isContactsVisible) {
        items = items.take(5);
      } else {
        items = items.whereType<_AddressItem>().take(5);
      }

      if (items.isNotEmpty) {
        l.add(_HeadingItem('Recent'));
        l.addAll(items);
      }
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
                      _addressStr = value;
                    });
                  },
                ),
                Gap(10),
                ElevatedButton(
                  child: Text('Confirm'),
                  onPressed: () {
                    final isNotEmpty = _addressStr?.isNotEmpty ?? false;

                    if (isNotEmpty) {
                      Navigator.pop(
                        context,
                        convex.Address2.fromStr(_addressStr),
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

class ActiveAccount2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Card(
      child: Column(
        children: [
          AddressTile2(address: appState.model.activeAddress2),
          FutureBuilder<Account>(
            future: appState
                .convexClient()
                .account2(address: appState.model.activeAddress2),
            builder: (context, snapshot) {
              var animatedChild;

              if (snapshot.connectionState == ConnectionState.waiting) {
                animatedChild = SizedBox(
                  height: 63,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'loading...',
                      style: TextStyle(color: Colors.black38),
                    ),
                  ),
                );
              } else {
                animatedChild = Padding(
                  padding: const EdgeInsets.all(16),
                  child: AccountTable(account: snapshot.data),
                );
              }

              return AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: animatedChild,
              );
            },
          ),
        ],
      ),
    );
  }
}

class AddressTile2 extends StatelessWidget {
  final Address2 address;
  final void Function() onTap;

  const AddressTile2({
    Key key,
    this.address,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final contact = appState.findContact2(address);

    final isAddressMine = appState.isAddressMine2(address);

    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            contact == null ? 'Unnamed' : '${contact.name}',
            style: Theme.of(context).textTheme.bodyText2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isAddressMine)
          Text(
            '(Owned by me)',
            style: Theme.of(context).textTheme.overline,
          ),
      ],
    );

    return ListTile(
      leading: aidenticon(address),
      trailing: IconButton(
        icon: Icon(Icons.copy),
        onPressed: () {
          Clipboard.setData(
            ClipboardData(
              text: address.toString(),
            ),
          );

          Scaffold.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Copied $address'),
              ),
            );
        },
      ),
      title: title,
      subtitle: Text(
        address.toString(),
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.caption,
      ),
      onTap: onTap,
    );
  }
}

class AccountTable extends StatelessWidget {
  final Account account;

  const AccountTable({Key key, this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultColumnWidth: IntrinsicColumnWidth(),
      children: [
        TableRow(
          children: [
            _cell(
              context,
              text: 'Coin Balance',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.caption,
            ),
            _cell(
              context,
              text: 'Memory Size',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.caption,
            ),
            _cell(
              context,
              text: 'Memory Allowance',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
        TableRow(
          children: [
            _cell(
              context,
              text: NumberFormat().format(
                account.balance,
              ),
            ),
            _cell(
              context,
              text: account.memorySize.toString(),
            ),
            _cell(
              context,
              text: account.memoryAllowance.toString(),
            ),
          ],
        )
      ],
    );
  }

  Widget _cell(
    BuildContext context, {
    String text,
    TextStyle style,
    TextAlign textAlign = TextAlign.right,
  }) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12),
        child: Text(
          text,
          textAlign: textAlign,
          style: style ?? Theme.of(context).textTheme.bodyText2,
        ),
      ),
    );
  }
}

class AnimatedListView extends StatelessWidget {
  final List<Widget> children;

  const AnimatedListView({Key key, this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animated = children
        .asMap()
        .entries
        .map(
          (e) => AnimationConfiguration.staggeredList(
            position: e.key,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: e.value,
              ),
            ),
          ),
        )
        .toList();

    return AnimationLimiter(
      child: ListView(
        children: animated,
      ),
    );
  }
}
