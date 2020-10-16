import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';

import '../wallet.dart' as wallet;

Widget _identicon() => FutureBuilder(
      future: wallet.read(),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<KeyPair>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.done) {
          var keyPair = snapshot.data.first;

          return IconButton(
            icon: SvgPicture.string(
              Jdenticon.toSvg(
                Sodium.bin2hex(keyPair.pk),
              ),
              fit: BoxFit.contain,
            ),
            onPressed: () {},
          );
        }

        return Center(child: CircularProgressIndicator());
      },
    );

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convexity'),
        actions: [
          _identicon(),
        ],
      ),
      body: HomeScreenBody(),
    );
  }
}

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: wallet.read(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<KeyPair>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Text(Sodium.bin2hex(snapshot.data.first.pk)),
              ],
            );
          }

          return Center(child: CircularProgressIndicator());
        },
      );
}
