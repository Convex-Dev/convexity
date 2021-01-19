import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import '../convex.dart';
import '../model.dart';
import '../widget.dart';

class AccountScreen extends StatelessWidget {
  final Address address;

  const AccountScreen({Key key, this.address}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Address _address =
        address ?? ModalRoute.of(context).settings.arguments;

    final contacts = context
        .select<AppState, Set<Contact>>((appState) => appState.model.contacts);

    final contact = contacts.firstWhere(
      (element) => element.address == _address,
      orElse: () => null,
    );

    final activeAddress = context
        .select<AppState, Address>((appState) => appState.model.activeAddress);

    final isMine = activeAddress == _address;

    final body = Container(
      padding: defaultScreenPadding,
      child: AccountScreenBody(address: _address),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(contact?.name ?? 'Not in Address Book'),
      ),
      body: isMine
          ? ClipRect(
              child: Banner(
                message: "My Account",
                color: Colors.orange,
                location: BannerLocation.topEnd,
                child: body,
              ),
            )
          : body,
    );
  }
}

class AccountScreenBody extends StatefulWidget {
  final Address address;

  const AccountScreenBody({Key key, this.address}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccountScreenBodyState();
}

class _AccountScreenBodyState extends State<AccountScreenBody> {
  Future<Account> account;

  @override
  void initState() {
    super.initState();

    account = context
        .read<AppState>()
        .convexClient()
        .account(address: widget.address);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.select<AppState, Set<Contact>>(
      (appState) => appState.model.contacts,
    );

    final contact = contacts.firstWhere(
      (_contact) => _contact.address == widget.address,
      orElse: () => null,
    );

    return FutureBuilder(
      future: account,
      builder: (BuildContext context, AsyncSnapshot<Account> snapshot) {
        var progressIndicator = Center(child: CircularProgressIndicator());

        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return progressIndicator;
          case ConnectionState.waiting:
            return progressIndicator;
          case ConnectionState.active:
            return progressIndicator;
          case ConnectionState.done:
            var account = snapshot.data;

            if (account == null) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text('Account not found.'),
                ),
              );
            }

            Widget _cell({
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

            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    QrImage(
                      data:
                          'https://convex.world/explorer/accounts/${widget.address.hex}',
                      version: QrVersions.auto,
                      size: 140,
                    ),
                    Gap(10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            ListTile(
                              leading: aidenticon(widget.address),
                              trailing: IconButton(
                                icon: Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: widget.address.toString(),
                                    ),
                                  );

                                  Scaffold.of(context)
                                    ..removeCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Copied ${widget.address}'),
                                      ),
                                    );
                                },
                              ),
                              title: Text(
                                widget.address.toString(),
                                style: Theme.of(context).textTheme.bodyText2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('Address'),
                            ),
                            Table(
                              defaultColumnWidth: IntrinsicColumnWidth(),
                              children: [
                                TableRow(
                                  children: [
                                    _cell(
                                      text: 'Balance',
                                      textAlign: TextAlign.left,
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                    _cell(
                                      text: 'Memory Size',
                                      textAlign: TextAlign.left,
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                    _cell(
                                      text: 'Memory Allowance',
                                      textAlign: TextAlign.left,
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    _cell(
                                      text: NumberFormat().format(
                                        account.balance,
                                      ),
                                    ),
                                    _cell(
                                      text: account.memorySize.toString(),
                                    ),
                                    _cell(
                                      text: account.memoryAllowance.toString(),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(contact != null ? Icons.delete : Icons.add),
                        label: Text(
                          contact != null
                              ? 'Remove from Address Book'
                              : 'Add to Address Book',
                        ),
                        onPressed: () {
                          if (contact == null) {
                            _addToAddressBook(context, address: widget.address);
                          } else {
                            _removeFromAddressBook(context, contact: contact);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
        }

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text('Account not found.'),
          ),
        );
      },
    );
  }

  void _addToAddressBook(BuildContext context, {Address address}) async {
    String alias;

    var confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  aidenticon(widget.address, width: 80, height: 80),
                  Gap(5),
                  Text(
                    widget.address.toString(),
                    style: Theme.of(context).textTheme.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap(5),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                    onChanged: (s) {
                      alias = s;
                    },
                  ),
                  Gap(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlineButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                      ),
                      Gap(10),
                      ElevatedButton(
                        child: const Text('Confirm'),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmation == true) {
      final _appState = context.read<AppState>();

      print('Alias $alias');

      final _newContact = Contact(
        name: alias,
        address: address,
      );

      _appState.addContact(_newContact, isPersistent: true);
    }
  }

  void _removeFromAddressBook(BuildContext context, {Contact contact}) async {
    var confirmation = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.help,
                size: 80,
                color: Colors.black12,
              ),
              Gap(10),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Remove ${contact.name} from Address Book?'),
              ),
              Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlineButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  Gap(10),
                  ElevatedButton(
                    child: const Text('Confirm'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );

    if (confirmation == true) {
      final _appState = context.read<AppState>();

      _appState.removeContact(contact, isPersistent: true);
    }
  }
}
