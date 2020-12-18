import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:tuple/tuple.dart';

import '../widget.dart';
import '../convex.dart';
import '../nav.dart';

class NonFungibleTokenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Tuple of NFT + ID + Data.
    final Tuple3<NonFungibleToken, int, Future<Result>> t =
        ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Non-Fungible Token')),
      body: NonFungibleTokenScreenBody(
        nonFungibleToken: t.item1,
        tokenId: t.item2,
        data: t.item3,
      ),
    );
  }
}

class NonFungibleTokenScreenBody extends StatefulWidget {
  final NonFungibleToken nonFungibleToken;
  final int tokenId;
  final Future<Result> data;

  const NonFungibleTokenScreenBody({
    Key key,
    @required this.nonFungibleToken,
    @required this.tokenId,
    @required this.data,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NonFungibleTokenScreenBodyState();
}

class _NonFungibleTokenScreenBodyState
    extends State<NonFungibleTokenScreenBody> {
  final demoImage =
      'https://vejasp.abril.com.br/wp-content/uploads/2016/11/13442__retirantes_-1944-de-candido-portinari-jpg.jpeg?quality=70&strip=info&w=1024';

  @override
  Widget build(BuildContext context) => Container(
        padding: defaultScreenPadding,
        child: ListView(
          children: [
            ListTile(
              title: Text(widget.tokenId.toString()),
              subtitle: Text('Token ID'),
            ),
            FutureBuilder<Result>(
              future: widget.data,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Result value is a map of attribute name to value - unless there's an error.
                  if (snapshot.data.errorCode != null) {
                    return ListTile(
                      leading: Icon(Icons.error),
                      title: Text(
                        'Sorry. It was not possible to query data for this token.',
                      ),
                    );
                  }

                  return ListTile(
                    title: Text(snapshot.data.value['name']),
                    subtitle: Text('Name'),
                  );
                }

                return Center(child: CircularProgressIndicator());
              },
            ),
            FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: demoImage,
            ),
            ElevatedButton(
              child: Text('Transfer'),
              onPressed: () {
                pushNonFungibleTransfer(
                  context,
                  nonFungibleToken: widget.nonFungibleToken,
                  tokenId: widget.tokenId,
                );
              },
            ),
          ],
        ),
      );
}
