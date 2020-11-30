import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../route.dart' as route;

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

class NewTokenScreenBody extends StatefulWidget {
  @override
  _NewTokenScreenBodyState createState() => _NewTokenScreenBodyState();
}

class _NewTokenScreenBodyState extends State<NewTokenScreenBody> {
  String _name;
  String _description;
  String _symbol;
  int _decimals;
  int _supply;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: TextField(
            autofocus: true,
            onChanged: (value) {
              _name = value;
            },
          ),
          subtitle: Text('Name'),
        ),
        ListTile(
          title: TextField(
            onChanged: (value) {
              _description = value;
            },
          ),
          subtitle: Text('Description'),
        ),
        ListTile(
          title: TextField(
            onChanged: (value) {
              _symbol = value;
            },
          ),
          subtitle: Text('Symbol'),
        ),
        ListTile(
          title: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              _decimals = int.tryParse(value);
            },
          ),
          subtitle: Text('Decimals'),
        ),
        ListTile(
          title: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              _supply = int.tryParse(value);
            },
          ),
          subtitle: Text('Supply'),
        ),
        Container(
          padding: EdgeInsets.all(15),
          child: ElevatedButton(
            child: Text('Create Token'),
            onPressed: () {
              var metadata = FungibleTokenMetadata(
                name: _name,
                description: _description,
                symbol: _symbol,
                decimals: _decimals,
              );

              // TODO: Create Asset on Convex Network.

              var fungible = FungibleToken(
                address: Address(hex: 'ABC1'),
                metadata: metadata,
              );

              context.read<AppState>().addMyToken(
                    AAsset(
                      type: AssetType.fungible,
                      asset: fungible,
                    ),
                  );

              showModalBottomSheet(
                isDismissible: false,
                enableDrag: false,
                context: context,
                builder: (context) {
                  return Container(
                    height: 300,
                    child: Center(
                      child: Column(
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
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
