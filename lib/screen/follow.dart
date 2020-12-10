import 'package:barcode_scan/barcode_scan.dart';
import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
      body: FollowAssetScreenBody(),
    );
  }
}

class FollowAssetScreenBody extends StatefulWidget {
  @override
  _FollowAssetScreenBodyState createState() => _FollowAssetScreenBodyState();
}

class _FollowAssetScreenBodyState extends State<FollowAssetScreenBody> {
  var selectedOption = _Option.scanQRCode;

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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          option(
            title: 'Scan QR Code',
            value: _Option.scanQRCode,
          ),
          option(
            title: 'Recommended',
            value: _Option.recommended,
          ),
          option(
            title: 'Asset Address',
            value: _Option.assetId,
          ),
          Gap(20),
          Expanded(
            child: OptionRenderer(
              option: selectedOption,
            ),
          )
        ],
      ),
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
  var _following = <AAsset>{};

  void initState() {
    super.initState();

    final appState = context.read<AppState>();

    var convexityClient = appState.convexityClient();

    if (convexityClient != null) {
      convexityClient.aassets().then((Set<AAsset> following) {
        // It's important to check if the Widget is mounted
        // because the user might change the selected option
        // while we're still loading the recommended Assets.
        if (mounted) {
          setState(
            () {
              this._isLoading = false;
              this._following = following ?? <AAsset>{};
            },
          );
        }
      });
    } else {
      this._isLoading = false;
    }
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
        children: _following
            .where(
              (AAsset aaset) =>
                  appState.model.following.contains(aaset) == false,
            )
            .map(
              (token) => fungibleTokenRenderer(
                fungible: token.asset as FungibleToken,
                balance: appState.fungibleClient().balance(
                      token: token.asset.address,
                      holder: appState.model.activeAddress,
                    ),
                onTap: (FungibleToken fungible) {
                  var aasset = AAsset(
                    type: AssetType.fungible,
                    asset: fungible,
                  );

                  context.read<AppState>().follow(
                        aasset,
                        isPersistent: true,
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

      var token = await convexity.aasset(scannedAddress);

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
            QrImage(
              data: 'Convexity',
              version: QrVersions.auto,
              size: 160,
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
                  ? fungibleTokenRenderer(
                      fungible: aasset.asset,
                      balance: appState.fungibleClient().balance(
                            token: aasset.asset.address,
                            holder: appState.model.activeAddress,
                          ),
                    )
                  : nonFungibleTokenRenderer(),
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
                      .aasset(Address.fromHex(address))
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
