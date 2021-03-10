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

  TextEditingController _ofController = TextEditingController();

  /// Set by [_refreshOfBalance].
  Future _ofBalance;

  /// Set by [_refreshWithBalance].
  Future _withBalance;

  /// Set by [_refreshQuote].
  Future<int> _quote;

  _ExchangeScreenBody2State(this._params);

  FungibleToken get _ofToken => _params.ofToken ?? _CVX;

  FungibleToken get _withToken => _params.withToken ?? _CVX;

  String get _actionText =>
      _params?.action == ExchangeAction.buy ? 'Buy' : 'Sell';

  String get _actionWithForText =>
      _params?.action == ExchangeAction.buy ? 'With' : 'For';

  @override
  void initState() {
    super.initState();

    _refreshBalance();
  }

  @override
  Widget build(BuildContext context) {
    final fungibles = context
        .watch<AppState>()
        .model
        .following
        .where((e) => e.type == AssetType.fungible)
        .map((e) => e.asset as FungibleToken)
        .toList();

    return SingleChildScrollView(
      child: SafeArea(
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
                  _actionText,
                  style: Theme.of(context).textTheme.headline5,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ofController,
                    autofocus: true,
                    onChanged: (s) {
                      setState(() {
                        _params = _params.copyWith(amount: s);

                        _refreshQuote();
                      });
                    },
                  ),
                ),
                Gap(40),
                Column(
                  children: [
                    _Dropdown<FungibleToken>(
                      active: _ofToken,
                      items: [_CVX, ...fungibles],
                      itemWidget: (fungible) => Text(
                        fungible.metadata.symbol,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onChanged: (e) {
                        setState(() {
                          final ofToken = e == _CVX ? null : e;

                          _params = _params.setOfToken(ofToken);

                          _refreshOfBalance();
                          _refreshQuote();
                        });
                      },
                    ),
                    Text(_ofToken.metadata.name),
                  ],
                ),
              ],
            ),
            Gap(5),
            // -- Of Token, or CVX, balance.
            Row(
              children: [
                _Balance(
                  token: _params.ofToken,
                  balance: _ofBalance,
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

                      final ofBalance = _ofBalance;
                      final withBalance = _withBalance;

                      _ofBalance = withBalance;
                      _withBalance = ofBalance;

                      _refreshQuote();
                    });
                  },
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  _actionWithForText,
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      .copyWith(color: Colors.black54),
                ),
              ],
            ),
            Row(
              children: [
                if (_quote == null)
                  Expanded(
                    child: Text('-'),
                  )
                else
                  FutureBuilder(
                    future: _quote,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Expanded(
                          child: Text('Getting quote...'),
                        );
                      }

                      if (snapshot.hasError) {
                        return Expanded(
                          child: Text('-'),
                        );
                      }

                      return Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _quoteText(snapshot.data),
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            Gap(5),
                            Text(
                              '(latest quote)',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                Gap(40),
                Column(
                  children: [
                    _Dropdown<FungibleToken>(
                      active: _withToken,
                      items: [_CVX, ...fungibles],
                      itemWidget: (fungible) => Text(
                        fungible.metadata.symbol,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onChanged: (e) {
                        setState(() {
                          final withToken = e == _CVX ? null : e;

                          _params = _params.setWithToken(withToken);

                          _refreshWithBalance();
                          _refreshQuote();
                        });
                      },
                    ),
                    Text(_withToken.metadata.name),
                  ],
                ),
              ],
            ),
            // -- With Token, or CVX, balance.
            Row(
              children: [
                _Balance(
                  token: _params.withToken,
                  balance: _withBalance,
                ),
              ],
            ),
            Gap(60),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                child: Text(
                  _actionText,
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      .copyWith(color: Colors.white),
                ),
                onPressed: _params.isAmountValid ? _buySell : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ofController.dispose();

    super.dispose();
  }

  void _buySell() async {
    final confirmation = await showModalBottomSheet(
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
                child: FutureBuilder(
                  future: _quote,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    // Example: Buy 1000 Token 1
                    final buyingSellingText =
                        '$_actionText ${_params.amount} ${_ofToken.metadata.name}';

                    // Example: 1,000 CVX
                    final quoteText =
                        '${_quoteText(snapshot.data)} ${_withToken.metadata.name}';

                    return Text(
                      '$buyingSellingText ${_actionWithForText.toLowerCase()} $quoteText?',
                      style: Theme.of(context).textTheme.bodyText2,
                    );
                  },
                ),
              ),
              Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  Gap(60),
                  ElevatedButton(
                    child: const Text('Confirm'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                ],
              )
            ],
          ),
        );
      },
    );

    if (confirmation != true) {
      return;
    }

    final appState = context.read<AppState>();

    final x = _params.action == ExchangeAction.buy
        ? (_params.withToken == null
            ? appState.torus().buyTokens(
                  ofToken: _params.ofToken.address,
                  amount: _params.amountInt,
                )
            : appState.torus().buy(
                  ofToken: _params.ofToken.address,
                  amount: _params.amountInt,
                  withToken: _params.withToken.address,
                ))
        : (_params.withToken == null
            ? appState.torus().sellTokens(
                  ofToken: _params.ofToken.address,
                  amount: _params.amountInt,
                )
            : appState.torus().sell(
                  ofToken: _params.ofToken.address,
                  amount: _params.amountInt,
                  withToken: _params.withToken?.address,
                ));

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Center(
            child: FutureBuilder(
              future: x,
              builder: (
                BuildContext context,
                AsyncSnapshot<int> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  logger.e(
                    'Failed to $_actionText: ${snapshot.error}',
                  );

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.error,
                        size: 80,
                        color: Colors.black12,
                      ),
                      Gap(10),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Sorry. It was not possible to ${_actionText.toLowerCase()} ${_ofToken.metadata.symbol}.\n\n${snapshot.error}',
                        ),
                      ),
                      Gap(10),
                      ElevatedButton(
                        child: const Text('Okay'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  );
                }

                final boughtOrSold =
                    _params.action == ExchangeAction.buy ? 'Bought' : 'Sold';

                // Example: 1,000 CVX
                final quoteText =
                    '${_quoteText(snapshot.data)} ${_withToken.metadata.name}';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.check,
                      size: 80,
                      color: Colors.green,
                    ),
                    Gap(10),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$boughtOrSold ${_params.amount} ${_ofToken.metadata.symbol} ${_actionWithForText.toLowerCase()} $quoteText.',
                          ),
                        ],
                      ),
                    ),
                    Gap(10),
                    ElevatedButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.pop(context);

                        setState(() {
                          // Buy/sell was successfull. Now let's make the UI ready for a new transaction:

                          // Refresh 'of Token' and 'with Token' balance.
                          _refreshBalance();

                          // Clear quote and amount.
                          _ofController.text = '';
                          _params = _params.emptyAmount();
                          _quote = null;
                        });
                      },
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _refreshOfBalance() {
    final appState = context.read<AppState>();

    final ofToken = _params.ofToken;

    _ofBalance = ofToken == null
        ? appState.convexClient().balance()
        : appState.assetLibrary().balance(asset: ofToken.address);
  }

  void _refreshWithBalance() {
    final appState = context.read<AppState>();

    final withToken = _params.withToken;

    _withBalance = withToken == null
        ? appState.convexClient().balance()
        : appState.assetLibrary().balance(asset: withToken.address);
  }

  void _refreshBalance() {
    _refreshOfBalance();
    _refreshWithBalance();
  }

  /// Query quote for 'with Token'.
  /// This method must be called whenever 'of Token' or 'with Token' changes.
  void _refreshQuote() {
    if (_params.amount == null || _params.amount.isEmpty) {
      logger.d('Amount is blank. Will set quote to null.');

      _quote = null;

      return;
    }

    try {
      _params.amountInt;
    } catch (e) {
      logger.e('Amount cannot be coerced to int. Will set quote to null.', e);

      _quote = null;

      return;
    }

    final torus = context.read<AppState>().torus();

    if (_params.action == ExchangeAction.buy) {
      _quote = torus.buyQuote(
        ofToken: _params.ofToken?.address,
        amount: _params.amountInt,
        withToken: _params.withToken?.address,
      );
    } else {
      _quote = torus.sellQuote(
        ofToken: _params.ofToken?.address,
        amount: _params.amountInt,
        withToken: _params.withToken?.address,
      );
    }
  }

  /// Returns quote formatted based on 'with Token'.
  /// If 'with Token' is selected, it will be formated using its metadata.
  /// If 'with Token' is null, it will be formatted as CVX.
  String _quoteText(int quote) => _params.withToken != null
      ? format.formatFungibleCurrency(
          metadata: _params.withToken.metadata,
          number: quote,
        )
      : format.formatCVX(quote);
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

class _Balance extends StatelessWidget {
  final FungibleToken token;
  final Future balance;

  const _Balance({
    Key key,
    this.token,
    this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: balance,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Spinner();
        } else {
          final s = snapshot.data == null
              ? ''
              : token == null
                  ? format.formatCVX(snapshot.data)
                  : format.formatFungibleCurrency(
                      metadata: token.metadata,
                      number: snapshot.data,
                    );

          return Container(
            height: 20,
            child: Row(
              children: [
                Text(
                  'BALANCE',
                  style: Theme.of(context).textTheme.caption,
                ),
                Gap(5),
                Text(s),
              ],
            ),
          );
        }
      },
    );
  }
}
