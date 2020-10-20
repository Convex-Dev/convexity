import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:provider/provider.dart';

import 'model.dart';

class IdenticonDropdown extends StatelessWidget {
  final KeyPair activeKeyPair;
  final List<KeyPair> allKeyPairs;

  const IdenticonDropdown({
    Key key,
    this.activeKeyPair,
    this.allKeyPairs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var activePK = Sodium.bin2hex(activeKeyPair.pk);

    var allPKs = allKeyPairs.map((_keyPair) => Sodium.bin2hex(_keyPair.pk));

    return DropdownButton<String>(
      value: activePK,
      items: allPKs
          .map(
            (s) => DropdownMenuItem(
              child: SvgPicture.string(
                Jdenticon.toSvg(s),
                fit: BoxFit.contain,
              ),
              value: s,
            ),
          )
          .toList(),
      onChanged: (_pk) {
        var selectedKeyPair = allKeyPairs
            .firstWhere((_keyPair) => _pk == Sodium.bin2hex(_keyPair.pk));

        context.read<AppState>().setActiveKeyPair(selectedKeyPair);
      },
    );
  }
}
