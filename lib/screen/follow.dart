import 'package:barcode_scan/barcode_scan.dart';
import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../widget.dart';

enum _Option {
  recommended,
  scanQRCode,
  search,
  myHoldings,
  assetId,
}

class FollowAssetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Follow Asset')),
      body: Container(
        padding: defaultScreenPadding,
        child: FollowAssetScreenBody(),
      ),
    );
  }
}

class FollowAssetScreenBody extends StatefulWidget {
  @override
  _FollowAssetScreenBodyState createState() => _FollowAssetScreenBodyState();
}

class _FollowAssetScreenBodyState extends State<FollowAssetScreenBody> {
  var selectedOption = _Option.recommended;

  Widget option({
    @required String title,
    @required _Option value,
  }) =>
      RadioListTile(
        title: Text(title),
        value: value,
        groupValue: selectedOption,
        onChanged: (value) {
          setState(() {
            selectedOption = value;
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    return OptionRenderer(
      option: selectedOption,
    );
  }
}

class OptionRenderer extends StatelessWidget {
  final _Option option;

  const OptionRenderer({Key key, this.option}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (option) {
      case _Option.recommended:
        return _Recommended();
      case _Option.scanQRCode:
        return _ScanQRCode();
      case _Option.search:
        return _Search();
      case _Option.myHoldings:
        return _MyHoldings();
      case _Option.assetId:
        return _AssetID();
    }

    throw Exception("No renderer for $option");
  }
}

class _Recommended extends StatefulWidget {
  @override
  _RecommendedState createState() => _RecommendedState();
}

class _RecommendedState extends State<_Recommended> {
  var _isLoading = true;
  var _assets = <AAsset>{};
  var _balanceCache = <Address, Future<int>>{};

  void initState() {
    super.initState();

    final appState = context.read<AppState>();
    final convexityClient = appState.convexityClient();
    final fungibleClient = appState.fungibleClient();

    if (convexityClient != null) {
      convexityClient.assets().then((Set<AAsset> assets) {
        // It's important to check if the Widget is mounted
        // because the user might change the selected option
        // while we're still loading the recommended Assets.
        if (mounted) {
          final xs = assets ?? <AAsset>{};

          final fungibles = xs
              .where(
                (aasset) => aasset.type == AssetType.fungible,
              )
              .map(
                (aasset) => MapEntry(
                  aasset.asset.address as Address,
                  fungibleClient.balance(
                    token: aasset.asset.address,
                    holder: appState.model.activeAddress,
                  ),
                ),
              );

          setState(
            () {
              _isLoading = false;
              _assets = xs;
              _balanceCache = Map<Address, Future<int>>.fromEntries(fungibles);
            },
          );
        }
      });
    } else {
      this._isLoading = false;
    }
  }

  void follow(
    BuildContext context, {
    AssetType type,
    Asset asset,
  }) {
    var aasset = AAsset(
      type: type,
      asset: asset,
    );

    context.read<AppState>().follow(aasset, isPersistent: true);

    Scaffold.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'You are following ${aasset.asset.metadata.name}',
            overflow: TextOverflow.clip,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: _assets
            .where(
              (AAsset asset) =>
                  appState.model.following.contains(asset) == false,
            )
            .map(
              (asset) => asset.type == AssetType.fungible
                  ? fungibleTokenCard(
                      fungible: asset.asset as FungibleToken,
                      balance: _balanceCache[asset.asset.address],
                      onTap: (FungibleToken fungible) {
                        follow(
                          context,
                          type: AssetType.fungible,
                          asset: fungible,
                        );
                      },
                    )
                  : nonFungibleTokenCard(
                      nonFungible: asset.asset as NonFungibleToken,
                      onTap: (NonFungibleToken nonFungible) {
                        follow(
                          context,
                          type: AssetType.nonFungible,
                          asset: nonFungible,
                        );
                      },
                    ),
            )
            .toList(),
      );
    }
  }
}

enum _ScanQRCodeStatus {
  ready,
  loading,
  loaded,
}

class _ScanQRCode extends StatefulWidget {
  @override
  _ScanQRCodeState createState() => _ScanQRCodeState();
}

class _ScanQRCodeState extends State<_ScanQRCode> {
  _ScanQRCodeStatus status = _ScanQRCodeStatus.ready;

  Address scannedAddress;
  AAsset aasset;

  void scan() async {
    var r = await BarcodeScanner.scan();
    var rawContent = r.rawContent ?? "";

    if (rawContent.isNotEmpty) {
      var scannedAddress = Address(hex: rawContent);

      setState(() {
        this.scannedAddress = scannedAddress;
        this.status = _ScanQRCodeStatus.loading;
      });

      var convexity = context.read<AppState>().convexityClient();

      print('Asset Metadata $scannedAddress');

      var token = await convexity.asset(scannedAddress);

      setState(() {
        status = _ScanQRCodeStatus.loaded;
      });

      print('Token $token');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _ScanQRCodeStatus.ready:
        return Column(
          children: [
            Icon(
              Icons.qr_code,
              size: 80,
            ),
            ElevatedButton(
              child: Text('Scan QR Code'),
              onPressed: () {
                scan();
              },
            ),
          ],
        );
      case _ScanQRCodeStatus.loading:
        return Column(
          children: [
            Text(scannedAddress.hex),
            CircularProgressIndicator(),
          ],
        );
      case _ScanQRCodeStatus.loaded:
        return Column(
          children: [
            Text(scannedAddress.hex),
          ],
        );
      default:
        return Text('-');
    }
  }
}

class _Search extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Search'),
    );
  }
}

class _MyHoldings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('My Holdings'),
    );
  }
}

class _AssetID extends StatefulWidget {
  @override
  _AssetIDState createState() => _AssetIDState();
}

class _AssetIDState extends State<_AssetID> {
  var status = AssetMetadataQueryStatus.ready;

  String address;
  AAsset aasset;

  Widget body(BuildContext context) {
    final appState = context.watch<AppState>();

    switch (status) {
      case AssetMetadataQueryStatus.ready:
        return Center(child: Text(''));

      case AssetMetadataQueryStatus.inProgress:
        return Center(child: CircularProgressIndicator());

      case AssetMetadataQueryStatus.done:
        return Column(
          children: [
            SizedBox(
              width: 160,
              child: aasset.type == AssetType.fungible
                  ? fungibleTokenCard(
                      fungible: aasset.asset,
                      balance: appState.fungibleClient().balance(
                            token: aasset.asset.address,
                            holder: appState.model.activeAddress,
                          ),
                    )
                  : nonFungibleTokenCard(
                      nonFungible: aasset.asset,
                    ),
            ),
            ElevatedButton(
              child: Text('Follow'),
              onPressed: () {
                context.read<AppState>().follow(aasset, isPersistent: true);

                Navigator.pop(context);
              },
            )
          ],
        );

      case AssetMetadataQueryStatus.missingMetadata:
        return Center(
          child: Text(
            'This Address is not registered with Convexity.',
            style: TextStyle(color: Colors.orange),
          ),
        );

      case AssetMetadataQueryStatus.notFound:
        return Center(
          child: Text('Sorry. The Asset was not found.'),
        );

      default:
        return Center(child: Text(''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Address',
          ),
          onChanged: (value) {
            setState(() {
              address = Address.trim0x(value);
              status = AssetMetadataQueryStatus.ready;
            });
          },
        ),
        TextButton(
          child: Text('Verify'),
          onPressed: (AssetMetadataQueryStatus.inProgress == status)
              ? null
              : () {
                  if (context.read<AppState>().convexityClient() == null) {
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Can't verify because Convexity Address is not set.",
                        ),
                      ),
                    );

                    return;
                  }

                  setState(() {
                    status = AssetMetadataQueryStatus.inProgress;
                  });

                  context
                      .read<AppState>()
                      .convexityClient()
                      .asset(Address.fromHex(address))
                      .then(
                    (_assetMetadata) {
                      // It's important to check wether the Widget is mounted,
                      // because the user might change the selected option
                      // while there is still a query a progress.
                      if (mounted) {
                        setState(() {
                          status = _assetMetadata == null
                              ? AssetMetadataQueryStatus.missingMetadata
                              : AssetMetadataQueryStatus.done;

                          aasset = _assetMetadata;
                        });
                      }
                    },
                  );
                },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: body(context),
        ),
      ],
    );
  }
}

enum AssetMetadataQueryStatus {
  /// Initial status.
  ready,

  /// Query is in progress.
  inProgress,

  /// The Asset exists on the Convex Network, but there is not metadata available.
  missingMetadata,

  /// The Asset doesn't exist on the Convex Network.
  notFound,

  /// The Asset exists on the Convex Network, and there is metadata available.
  done,
}
