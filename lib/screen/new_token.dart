import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../route.dart' as route;

enum _NewTokenStatus {
  creatingToken,
  creatingTokenError,
  registeringToken,
  registeringTokenError,
  success,
}

class NewTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Token'),
      ),
      body: NewTokenScreenBody(),
    );
  }
}

abstract class _NewToken {}

@immutable
class _NewFungibleToken implements _NewToken {
  final String name;
  final String description;
  final String symbol;
  final String currencySymbol;
  final int decimals;
  final int supply;

  _NewFungibleToken({
    @required this.name,
    @required this.description,
    @required this.symbol,
    @required this.currencySymbol,
    @required this.decimals,
    @required this.supply,
  });
}

@immutable
class _NewNonFungibleToken implements _NewToken {
  final String name;
  final String uri;

  _NewNonFungibleToken({
    @required this.name,
    this.uri,
  });
}

class _CreateToken extends StatefulWidget {
  final _NewToken newToken;

  const _CreateToken(this.newToken, {Key key}) : super(key: key);

  @override
  _CreateTokenState createState() => _CreateTokenState();
}

class _CreateTokenState extends State<_CreateToken> {
  var _newTokenStatus = _NewTokenStatus.creatingToken;

  void createToken() async {
    // The process of creating a new user-defined Token on the Convex Network is divided in 2 steps:
    // 1. Deploy/create the Token;
    // 2. Register its metadata with the Convexity registry.

    var appState = context.read<AppState>();

    if (widget.newToken is _NewFungibleToken) {
      final _newFungibleToken = widget.newToken as _NewFungibleToken;

      Result myTokenResult;

      // Step 1 - deploy.
      try {
        myTokenResult = await appState.fungibleClient().createToken(
              holder: appState.model.activeAddress,
              holderSecretKey: appState.model.activeKeyPair.sk,
              supply: _newFungibleToken.supply,
            );
      } on Exception catch (e) {
        print('Failed to create Token: $e');

        setState(() {
          _newTokenStatus = _NewTokenStatus.creatingTokenError;
        });

        return;
      }

      if (myTokenResult.errorCode != null) {
        setState(() {
          _newTokenStatus = _NewTokenStatus.creatingTokenError;
        });

        return;
      }

      // Step 2 - register metadata.
      var metadata = FungibleTokenMetadata(
        name: _newFungibleToken.name,
        description: _newFungibleToken.description,
        symbol: _newFungibleToken.symbol,
        currencySymbol: _newFungibleToken.currencySymbol,
        decimals: _newFungibleToken.decimals,
      );

      var fungible = FungibleToken(
        address: Address(hex: myTokenResult.value as String),
        metadata: metadata,
      );

      var aasset = AAsset(
        type: AssetType.fungible,
        asset: fungible,
      );

      setState(() {
        _newTokenStatus = _NewTokenStatus.registeringToken;
      });

      Result registerResult;

      try {
        registerResult = await appState.convexityClient().requestToRegister(
              holder: appState.model.activeAddress,
              holderSecretKey: appState.model.activeKeyPair.sk,
              aasset: aasset,
            );
      } on Exception catch (e) {
        print('Failed to register Token: $e');

        setState(() {
          _newTokenStatus = _NewTokenStatus.registeringTokenError;
        });

        return;
      }

      if (registerResult.errorCode != null) {
        setState(() {
          _newTokenStatus = _NewTokenStatus.registeringTokenError;
        });

        return;
      }

      appState.addMyToken(
        aasset,
        isPersistent: true,
      );

      setState(() {
        _newTokenStatus = _NewTokenStatus.success;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    createToken();
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
      case _NewTokenStatus.registeringToken:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            CircularProgressIndicator(),
            const Text('Registering Token...'),
          ],
        );
      case _NewTokenStatus.registeringTokenError:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Icon(
              Icons.error,
              size: 80,
              color: Colors.black12,
            ),
            const Text('Sorry. It was not possible to register your Token.'),
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
                ModalRoute.withName(route.myTokens),
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

class NewTokenScreenBody extends StatefulWidget {
  @override
  _NewTokenScreenBodyState createState() => _NewTokenScreenBodyState();
}

class _NewTokenScreenBodyState extends State<NewTokenScreenBody> {
  final _formKey = GlobalKey<FormState>();

  var _assetType = AssetType.fungible;

  String _name;
  String _uri;
  String _description;
  String _symbol;
  String _currencySymbol;
  int _decimals;
  int _supply;

  List<Widget> fungibleChildren() {
    return [
      ListTile(
        title: TextFormField(
          validator: (value) {
            if (value.isEmpty) {
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
            if (value.isEmpty) {
              return 'Required';
            }

            return null;
          },
          onChanged: (value) {
            setState(() {
              _description = value;
            });
          },
        ),
        subtitle: Text('Description'),
      ),
      ListTile(
        title: TextFormField(
          validator: (value) {
            if (value.isEmpty) {
              return 'Required';
            }

            return null;
          },
          onChanged: (value) {
            setState(() {
              _symbol = value;
            });
          },
        ),
        subtitle: Text('Symbol'),
      ),
      ListTile(
        title: TextFormField(
          validator: (value) {
            if (value.isEmpty) {
              return 'Required';
            }

            return null;
          },
          onChanged: (value) {
            setState(() {
              _currencySymbol = value;
            });
          },
        ),
        subtitle: Text('Currency Symbol'),
      ),
      ListTile(
        title: TextFormField(
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value.isEmpty) {
              return 'Required';
            }

            return null;
          },
          onChanged: (value) {
            setState(() {
              _decimals = int.tryParse(value);
            });
          },
        ),
        subtitle: Text('Decimals'),
      ),
      ListTile(
        title: TextFormField(
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value.isEmpty) {
              return 'Required';
            }

            return null;
          },
          onChanged: (value) {
            setState(() {
              _supply = int.tryParse(value);
            });
          },
        ),
        subtitle: Text('Supply'),
      ),
    ];
  }

  List<Widget> nonFungibleChildren() {
    return [
      ListTile(
        title: TextFormField(
          validator: (value) {
            if (value.isEmpty) {
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
            if (value.isEmpty) {
              return 'Required';
            }

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
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          RadioListTile<AssetType>(
            title: const Text('Fungible'),
            value: AssetType.fungible,
            groupValue: _assetType,
            onChanged: (value) {
              setState(() {
                _assetType = value;
              });
            },
          ),
          RadioListTile<AssetType>(
            title: const Text('Non-Fungible'),
            value: AssetType.nonFungible,
            groupValue: _assetType,
            onChanged: (value) {
              setState(() {
                _assetType = value;
              });
            },
          ),
          if (_assetType == AssetType.fungible)
            ...fungibleChildren()
          else
            ...nonFungibleChildren(),
          Container(
            padding: EdgeInsets.all(15),
            child: ElevatedButton(
              child: Text('Create Token'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  var newToken;

                  if (_assetType == AssetType.fungible) {
                    newToken = _NewFungibleToken(
                      name: _name,
                      description: _description,
                      symbol: _symbol,
                      currencySymbol: _currencySymbol,
                      decimals: _decimals,
                      supply: _supply,
                    );
                  } else {
                    newToken = _NewNonFungibleToken(
                      name: _name,
                      uri: "",
                    );
                  }

                  showModalBottomSheet(
                    isDismissible: false,
                    enableDrag: false,
                    context: context,
                    builder: (context) {
                      return Container(
                        height: 300,
                        child: Center(
                          child: _CreateToken(newToken),
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
