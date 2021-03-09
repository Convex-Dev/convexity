import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

import '../convex.dart';
import '../logger.dart';
import '../model.dart';
import '../widget.dart';
import '../nav.dart' as nav;
import '../format.dart' as format;

class ExchangeScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ExchangeParams params = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Exchange')),
      body: Container(
        padding: defaultScreenPadding,
        child: ExchangeScreenBody2(
          params: params,
        ),
      ),
    );
  }
}

class ExchangeScreenBody2 extends StatefulWidget {
  final ExchangeParams params;

  ExchangeScreenBody2({Key key, this.params}) : super(key: key);

  @override
  _ExchangeScreenBody2State createState() => _ExchangeScreenBody2State(params);
}

class _ExchangeScreenBody2State extends State<ExchangeScreenBody2> {
  ExchangeParams _params;

  _ExchangeScreenBody2State(this._params);

  FungibleToken get _ofToken => _params.ofToken ?? _CVX;

  FungibleToken get _withToken => _params.withToken ?? _CVX;

  String get _actionText =>
      _params?.action == ExchangeAction.buy ? 'Buy' : 'Sell';

  String get _actionWithForText =>
      _params?.action == ExchangeAction.buy ? 'With' : 'For';

  @override
  Widget build(BuildContext context) {
    final fungibles = context
        .watch<AppState>()
        .model
        .following
        .where((e) => e.type == AssetType.fungible)
        .map((e) => e.asset as FungibleToken)
        .toList();

    return Center(
      child: Column(
        children: [
          _BuySellToggle(
            selected: _params.action,
            onPressed: (action) {
              setState(() {
                _params = _params.copyWith(action: action);
              });
            },
          ),
          Gap(30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Of',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Gap(10),
              Text(
                _ofToken.metadata.name,
                style: Theme.of(context).textTheme.overline,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                ),
              ),
              Gap(40),
              _Dropdown<FungibleToken>(
                active: _params.ofToken ?? _CVX,
                items: [_CVX, ...fungibles],
                itemWidget: (fungible) => Text(fungible.metadata.name),
                onChanged: (e) {
                  setState(() {
                    final ofToken = e == _CVX ? null : e;

                    _params = _params.setOfToken(ofToken);
                  });
                },
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.swap_vert,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _params = _params.swap();
                  });
                },
              ),
            ),
          ),
          Row(
            children: [
              Text(
                _actionWithForText,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Gap(10),
              Text(
                _withToken.metadata.name,
                style: Theme.of(context).textTheme.overline,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                ),
              ),
              Gap(40),
              _Dropdown<FungibleToken>(
                active: _params.withToken ?? _CVX,
                items: [_CVX, ...fungibles],
                itemWidget: (fungible) => Text(fungible.metadata.name),
                onChanged: (e) {
                  setState(() {
                    final withToken = e == _CVX ? null : e;

                    _params = _params.setWithToken(withToken);
                  });
                },
              ),
            ],
          ),
          Gap(30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              child: Text(_actionText),
              onPressed: (_params.amount != null && _params.amount.isNotEmpty)
                  ? () {}
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: non_constant_identifier_names
final _CVX = FungibleToken(
  address: Address(-1),
  metadata: FungibleTokenMetadata(
    name: 'CVX',
    description: 'Convex Coin',
    symbol: 'CVX',
    currencySymbol: '\$',
    decimals: 0,
  ),
);

class _BuySellToggle extends StatelessWidget {
  final ExchangeAction selected;
  final void Function(ExchangeAction action) onPressed;

  const _BuySellToggle({Key key, this.selected, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      // This order is import for the [onPressed] callback.
      children: [
        Text('Buy'),
        Text('Sell'),
      ],
      isSelected: [
        selected == ExchangeAction.buy,
        selected == ExchangeAction.sell,
      ],
      onPressed: (i) {
        final action = i == 0 ? ExchangeAction.buy : ExchangeAction.sell;

        if (onPressed != null) {
          onPressed(action);
        }
      },
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T active;
  final List<T> items;
  final Widget Function(T item) itemWidget;
  final void Function(T t) onChanged;

  const _Dropdown({
    Key key,
    this.active,
    this.items,
    this.itemWidget,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: active,
      items: items
          .map(
            (t) => DropdownMenuItem<T>(
              value: t,
              child: itemWidget(t),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
