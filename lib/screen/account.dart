import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  Widget _addressInfo(String account) {
    return StatelessWidgetBuilder(
      (context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    Gap(4),
                    SelectableText(
                      account,
                      showCursor: false,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
              ),
              QrImage(
                data: widget.address.hex,
                version: QrVersions.auto,
                size: 80,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    @required String label,
    @required String value,
  }) {
    return StatelessWidgetBuilder(
      (context) => Card(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(color: Colors.black54, fontSize: 16.0),
                    ),
                    Text(
                      value,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
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

            final fields = [
              _addressInfo(account.address.toString()),
              _field(
                label: "Balance",
                value: account.balance.toString(),
              ),
              _field(
                label: "Memory Size",
                value: account.memorySize.toString(),
              ),
              _field(
                label: "Memory Allowance",
                value: account.memoryAllowance.toString(),
              ),
            ];

            final animated = fields
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

            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: AnimationLimiter(
                      child: ListView(
                        children: animated,
                      ),
                    ),
                  ),
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
                Icons.person,
                size: 80,
                color: Colors.black12,
              ),
              Gap(10),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [],
                ),
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

      final _newContact = Contact(
        name: 'Bla',
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
