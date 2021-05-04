import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import 'convex.dart';
import 'logger.dart';
import 'model.dart';
import 'convex.dart' as convex;
import 'format.dart';
import 'nav.dart' as nav;
import 'currency.dart' as currency;

const defaultScreenPadding = EdgeInsets.all(12);

const defaultButtonHeight = 52.0;

class StatelessWidgetBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const StatelessWidgetBuilder(
    this.builder, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}

Widget identicon(
  String bytes, {
  double? width,
  double? height,
}) =>
    SvgPicture.string(
      Jdenticon.toSvg(bytes),
      width: width,
      height: height,
    );

Widget aidenticon(
  Address address, {
  double? width,
  double? height,
}) =>
    identicon(
      address.value.toString(),
      width: width,
      height: height,
    );

class Identicon extends StatelessWidget {
  final KeyPair keyPair;

  const Identicon({Key? key, required this.keyPair}) : super(key: key);

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
    Key? key,
    required this.address,
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
              address.toString(),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      );
}

class IdenticonDropdown extends StatelessWidget {
  final KeyPair? activeKeyPair;
  final List<KeyPair>? allKeyPairs;
  final double? width;
  final double? height;

  const IdenticonDropdown({
    Key? key,
    this.activeKeyPair,
    this.allKeyPairs,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var activePK = Sodium.bin2hex(activeKeyPair!.pk);

    var allPKs = allKeyPairs!.map((_keyPair) => Sodium.bin2hex(_keyPair.pk));

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
      onChanged: (_pk) {},
    );
  }
}

class FungibleTokenCard extends StatelessWidget {
  final convex.FungibleToken? fungible;
  final Future? balance;
  final bool? isMine;
  final void Function(convex.FungibleToken)? onTap;

  const FungibleTokenCard({
    Key? key,
    required this.fungible,
    required this.balance,
    this.isMine,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_money,
            size: 30,
            color: Colors.orangeAccent,
          ),
          Gap(10),
          Text(
            fungible!.metadata.tickerSymbol,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.caption,
          ),
          Gap(4),
          Text(
            fungible!.metadata.name,
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
            builder: (context, snapshot) => Container(
              height: 30,
              child: snapshot.connectionState == ConnectionState.waiting
                  ? Text(
                      'Getting balance...',
                      style: Theme.of(context).textTheme.caption,
                    )
                  : Text(
                      snapshot.data != null
                          ? formatFungibleCurrency(
                              metadata: fungible!.metadata,
                              number: snapshot.data as int,
                            )
                          : '-',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
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
              child: isMine ?? false
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
                  onTap!(fungible!);
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
  }
}

class NonFungibleTokenCard extends StatelessWidget {
  final convex.NonFungibleToken? nonFungible;
  final void Function(convex.NonFungibleToken)? onTap;

  const NonFungibleTokenCard({
    Key? key,
    required this.nonFungible,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final container = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.videogame_asset,
          size: 30,
          color: Colors.orangeAccent,
        ),
        Gap(10),
        Text(
          nonFungible!.metadata.name!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.caption,
          overflow: TextOverflow.ellipsis,
        ),
        Gap(4),
        Text(
          nonFungible!.metadata.description!,
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
                  onTap!(nonFungible!);
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
  }
}

// ignore: must_be_immutable
class AssetCollection extends StatefulWidget {
  final Set<AAsset> assets = {};
  final Map<AAsset, Future> balanceCache = {};

  late String empty;
  void Function(AAsset)? onAssetTap;

  AssetCollection({
    Key? key,
    required Iterable<AAsset> assets,
    void Function(AAsset)? onAssetTap,
    Map<AAsset, Future>? balanceCache,
    String? empty,
  }) : super(key: key) {
    this.empty = empty ?? 'Nothing to show';
    this.assets.addAll(assets);
    this.onAssetTap = onAssetTap;

    if (balanceCache != null) {
      this.balanceCache.addAll(balanceCache);
    }
  }

  @override
  _AssetCollectionState createState() => _AssetCollectionState();
}

class _AssetCollectionState extends State<AssetCollection> {
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
        // We don't need to query the balance for this Asset
        // if there's already one available in the cache.
        // Notice that the cache *is not* updated.
        final balance = widget.balanceCache[aasset] ??
            appState.assetLibrary().balance(
                  asset: aasset.asset.address,
                  owner: appState.model.activeAddress,
                );

        if (aasset.type == AssetType.fungible) {
          final mine = appState.model.myTokens.firstWhereOrNull(
            (myToken) => myToken.asset.address == aasset.asset.address,
          );

          return FungibleTokenCard(
            isMine: mine != null,
            fungible: aasset.asset as convex.FungibleToken?,
            balance: balance,
            onTap: (fungible) {
              final asset = AAsset(
                type: AssetType.fungible,
                asset: fungible,
              );

              // On tap behavior is conditional to having explicitly
              // set a callback for when tapping on a Asset.
              // If it is set, call the callback and return.
              // Otherwise, push the Asset screen.

              if (widget.onAssetTap != null) {
                widget.onAssetTap!(asset);

                return;
              }

              _pushAsset(
                context: context,
                aasset: aasset,
                balance: balance,
              );
            },
          );
        }

        return NonFungibleTokenCard(
          nonFungible: aasset.asset as convex.NonFungibleToken?,
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

  void _pushAsset({
    required BuildContext context,
    required AAsset aasset,
    required Future balance,
  }) async {
    final result = await nav.pushAsset(
      context,
      aasset: aasset,
      balance: balance,
    );

    logger.d('Asset $aasset balance $result.');

    setState(() {
      // Clear cache to 'force' a balance refresh.
      widget.balanceCache.clear();
    });
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
  final convex.Address? address;

  _AddressItem(this.address);

  Widget build(BuildContext context) => ListTile(
        leading: aidenticon(address!),
        title: Text('Not in Address Book'),
        subtitle: Text(address.toString()),
        onTap: () {
          Navigator.pop(context, address);
        },
      );
}

/// Shows a Modal Bottom Sheet UI to select an Account.
Future<convex.Address?> selectAccountModal(BuildContext context) =>
    showModalBottomSheet<convex.Address>(
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

Widget selectAccountScreen({SelectAccountParams? params}) =>
    StatelessWidgetBuilder((context) {
      SelectAccountParams _params = params ??
          ModalRoute.of(context)!.settings.arguments as SelectAccountParams;

      return Scaffold(
        appBar: AppBar(title: Text(_params.title)),
        body: _SelectAccount(params: _params),
      );
    });

class _SelectAccount extends StatefulWidget {
  final SelectAccountParams? params;

  const _SelectAccount({Key? key, this.params}) : super(key: key);

  @override
  _SelectAccountState createState() => _SelectAccountState();
}

class _SelectAccountState extends State<_SelectAccount> {
  String? _addressStr;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final l = <_AWidget>[];

    // Add recent activities.
    if (widget.params!.isRecentsVisible &&
        appState.model.activities.isNotEmpty) {
      // Map to Address, and then cast to a Set to remove duplicates.
      final recent = appState.model.activities
          .where((activity) => activity.type == ActivityType.transfer)
          .map((activity) => (activity.payload as FungibleTransferActivity).to)
          .toSet();

      var items = recent
          .map((to) {
            // Check if address is saved in the Address Book.
            final contact = appState.model.contacts.firstWhereOrNull(
              (contact) => contact.address == to,
            );

            // Replace an Address item for a Contact item
            // if address is in the Address Book.
            return contact != null ? _ContactItem(contact) : _AddressItem(to);
          })
          .toList()
          .reversed;

      // If [isContactsVisible] is true, we simply take the last 5.
      // Otherwise, we need to check and remove contacts.
      if (widget.params!.isContactsVisible) {
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
    if (widget.params!.isContactsVisible &&
        appState.model.contacts.isNotEmpty) {
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
                        convex.Address.fromStr(_addressStr!),
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

class AccountCard extends StatelessWidget {
  final Address address;
  final Future<Account> account;

  const AccountCard({
    Key? key,
    required this.address,
    required this.account,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          AddressTile(address: address),
          FutureBuilder<Account>(
            future: account,
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
                  child: AccountTable(account: snapshot.data!),
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

class AddressTile extends StatelessWidget {
  final Address? address;
  final void Function()? onTap;

  const AddressTile({
    Key? key,
    this.address,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final contact = appState.findContact(address);

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
      leading: aidenticon(address!),
      trailing: IconButton(
        icon: Icon(Icons.copy),
        onPressed: () {
          Clipboard.setData(
            ClipboardData(
              text: address.toString(),
            ),
          );

          ScaffoldMessenger.of(context)
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

  const AccountTable({Key? key, required this.account}) : super(key: key);

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
              text: currency
                  .copperTo(account.balance, toUnit: currency.CvxUnit.gold)
                  .toStringAsPrecision(9),
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
    required String text,
    TextStyle? style,
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
  final List<Widget>? children;

  const AnimatedListView({Key? key, this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animated = children!
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

// ignore: non_constant_identifier_names
Widget Spinner() => SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    );

class Dropdown<T> extends StatelessWidget {
  final T? active;
  final List<T>? items;
  final Widget Function(T item)? itemWidget;
  final void Function(T? t)? onChanged;

  const Dropdown({
    Key? key,
    this.active,
    this.items,
    this.itemWidget,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: active,
      items: items!
          .map(
            (t) => DropdownMenuItem<T>(
              value: t,
              child: itemWidget!(t),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class NonFungibleGridTile extends StatelessWidget {
  final int tokenId;
  final Future<Result> data;
  final void Function() onTap;

  const NonFungibleGridTile({
    Key? key,
    required this.tokenId,
    required this.data,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result>(
      future: data,
      builder: (context, snapshot) {
        final subtitle = AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: snapshot.connectionState == ConnectionState.waiting
              ? Text('')
              : (snapshot.data!.errorCode != null
                  ? Text('')
                  : Text(snapshot.data!.value['name'])),
        );

        final child = AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: snapshot.connectionState == ConnectionState.waiting
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : (snapshot.data!.value['uri'] == null
                  ? Icon(
                      Icons.image,
                      size: 40,
                    )
                  : _nonFungibleImage(snapshot.data!.value['uri'])),
        );

        return InkWell(
          child: GridTile(
            footer: GridTileBar(
              title: Text('#$tokenId'),
              subtitle: subtitle,
              backgroundColor: Colors.black45,
            ),
            child: child,
          ),
          onTap: onTap,
        );
      },
    );
  }

  Widget _nonFungibleImage(String uri) {
    final fallback = Icon(
      Icons.image,
      size: 40,
    );

    try {
      if (Uri.parse(uri).isAbsolute == false) {
        return fallback;
      }

      return FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: uri,
      );
    } catch (e) {
      logger.e('Failed to load image: $e');

      return fallback;
    }
  }
}
