import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../convex.dart';
import '../model.dart';
import '../widget.dart';
import '../route.dart' as route;

class NewNonFungibleTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NonFungibleToken? nonFungibleToken =
        ModalRoute.of(context)!.settings.arguments as NonFungibleToken?;

    return Scaffold(
      appBar: AppBar(
        title: Text('New NFT'),
      ),
      body: Container(
        padding: defaultScreenPadding,
        child: NewNonFungibleTokenScreenBody(nonFungibleToken),
      ),
    );
  }
}

class NewNonFungibleTokenScreenBody extends StatefulWidget {
  final NonFungibleToken? _nonFungibleToken;

  const NewNonFungibleTokenScreenBody(this._nonFungibleToken, {Key? key})
      : super(key: key);

  @override
  _NewNonFungibleTokenScreenBodyState createState() =>
      _NewNonFungibleTokenScreenBodyState();
}

class _NewNonFungibleTokenScreenBodyState
    extends State<NewNonFungibleTokenScreenBody> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _uri;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          ListTile(
            title: TextFormField(
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Required';
                }

                return null;
              },
              onChanged: (value) {
                setState(() {
                  _name = value;
                });
              },
            ),
            subtitle: Text('Name'),
          ),
          ListTile(
            title: TextFormField(
              validator: (value) {
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _uri = value;
                });
              },
            ),
            subtitle: Text('URI'),
          ),
          Container(
            padding: EdgeInsets.only(top: 20),
            child: ElevatedButton(
              child: Text('Create Token'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final _newToken = _NewNonFungibleToken(
                    name: _name,
                    uri: _uri,
                  );

                  showModalBottomSheet(
                    isDismissible: false,
                    enableDrag: false,
                    context: context,
                    builder: (context) {
                      return Container(
                        height: 300,
                        child: Center(
                          child: _CreateToken(
                            nonFungibleToken: widget._nonFungibleToken,
                            newToken: _newToken,
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _NewNonFungibleToken {
  final String? name;
  final String? uri;

  _NewNonFungibleToken({
    required this.name,
    this.uri,
  });
}

class _CreateToken extends StatefulWidget {
  final NonFungibleToken? nonFungibleToken;
  final _NewNonFungibleToken? newToken;

  const _CreateToken({
    Key? key,
    this.nonFungibleToken,
    this.newToken,
  }) : super(key: key);

  @override
  _CreateTokenState createState() => _CreateTokenState();
}

enum _NewTokenStatus {
  creatingToken,
  creatingTokenError,
  success,
}

class _CreateTokenState extends State<_CreateToken> {
  var _newTokenStatus = _NewTokenStatus.creatingToken;

  void _createToken() async {
    var appState = context.read<AppState>();

    Result myTokenResult;

    try {
      final _uri =
          widget.newToken!.uri == null ? 'nil' : '"${widget.newToken!.uri}"';

      myTokenResult = await appState.convexClient().transact(
            source: '(call ${widget.nonFungibleToken!.address} '
                '(create-token {:name "${widget.newToken!.name}", :uri $_uri} nil) )',
          );
    } catch (e, s) {
      print('Failed to create Token: $e $s');

      setState(() {
        _newTokenStatus = _NewTokenStatus.creatingTokenError;
      });

      return;
    }

    if (myTokenResult.errorCode != null) {
      print('Failed to create Token: ${myTokenResult.value}');

      setState(() {
        _newTokenStatus = _NewTokenStatus.creatingTokenError;
      });

      return;
    }

    setState(() {
      _newTokenStatus = _NewTokenStatus.success;
    });
  }

  @override
  void initState() {
    super.initState();

    _createToken();
  }

  @override
  Widget build(BuildContext context) {
    switch (_newTokenStatus) {
      case _NewTokenStatus.creatingToken:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            CircularProgressIndicator(),
            const Text('Creating Token...'),
          ],
        );
      case _NewTokenStatus.creatingTokenError:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Icon(
              Icons.error,
              size: 80,
              color: Colors.black12,
            ),
            const Text('Sorry. It was not possible to create your Token.'),
            ElevatedButton(
              child: const Text('Okay'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      case _NewTokenStatus.success:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Icon(
              Icons.check,
              size: 80,
              color: Colors.black12,
            ),
            const Text('Your Token is ready.'),
            ElevatedButton(
              child: const Text('Done'),
              onPressed: () => Navigator.popUntil(
                context,
                ModalRoute.withName(route.ASSET),
              ),
            ),
          ],
        );
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            CircularProgressIndicator(),
          ],
        );
    }
  }
}
