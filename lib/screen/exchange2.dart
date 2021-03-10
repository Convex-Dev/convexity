import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../convex.dart';
import '../logger.dart';
import '../model.dart';
import '../widget.dart';
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

  Future<double> _price;

  /// Set by [_refreshOfMarketPrice].
  Future<double> _ofMarketPrice;

  /// Set by [_refreshWithMarketPrice].
  Future<double> _withMarketPrice;

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
    _refreshPrice();
    _refreshOfMarketPrice();
    _refreshWithMarketPrice();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final fungibles = appState.model.following
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
            Gap(20),
            _MarketPrice(
              params: _params,
              price: _price,
            ),
            Container(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _actionText,
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ],
                  ),
                  // It's null if 'of Token' is CVX - doesn't make sense to check CVX.
                  if (_ofMarketPrice != null)
                    _MarketCheck(
                      token: _params.ofToken,
                      market: _ofMarketPrice,
                      onCreated: (shares) {
                        setState(() {
                          _refreshPrice();
                          _refreshOfBalance();
                          _refreshOfMarketPrice();
                          _refreshQuote();
                        });
                      },
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: _ofMarketPrice,
                    builder: (context, snapshot) {
                      return TextField(
                        controller: _ofController,
                        autofocus: true,
                        enabled: _ofToken == _CVX || snapshot.hasData,
                        onChanged: (s) {
                          setState(() {
                            _params = _params.copyWith(amount: s);

                            _refreshQuote();
                          });
                        },
                      );
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

                          _refreshPrice();
                          _refreshOfBalance();
                          _refreshOfMarketPrice();
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

                      final ofMarketPrice = _ofMarketPrice;
                      final withMarketPrice = _withMarketPrice;

                      _ofMarketPrice = withMarketPrice;
                      _withMarketPrice = ofMarketPrice;

                      _refreshQuote();
                    });
                  },
                ),
              ),
            ),
            Container(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _actionWithForText,
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        .copyWith(color: Colors.black54),
                  ),
                  // It's null if 'with Token' is CVX - doesn't make sense to check CVX.
                  if (_withMarketPrice != null)
                    _MarketCheck(
                      token: _params.withToken,
                      market: _withMarketPrice,
                      onCreated: (shares) {
                        setState(() {
                          _refreshPrice();
                          _refreshWithBalance();
                          _refreshWithMarketPrice();
                          _refreshQuote();
                        });
                      },
                    ),
                ],
              ),
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

                      if (snapshot.hasError || snapshot.data == null) {
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

                          _refreshPrice();
                          _refreshWithBalance();
                          _refreshWithMarketPrice();
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
            FutureBuilder(
              future: _quote,
              builder: (context, snapshot) => SizedBox(
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
                  onPressed:
                      snapshot.connectionState == ConnectionState.waiting ||
                              snapshot.data == null
                          ? null
                          : _buySell,
                ),
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

  void _refreshPrice() {
    final torus = context.read<AppState>().torus();

    if (_params.ofToken == null) {
      return;
    }

    logger.d(
      'Of Token: ${_params.ofToken?.address}, With Token: ${_params.withToken?.address}',
    );

    _price = torus.price(
      ofToken: _params.ofToken?.address,
      withToken: _params.withToken?.address,
    );
  }

  /// Query price for 'of Token'.
  ///
  /// Set it to `null` if 'of Token' is null.
  void _refreshOfMarketPrice() {
    if (_params.ofToken == null) {
      _ofMarketPrice = null;

      return;
    }

    final torus = context.read<AppState>().torus();

    _ofMarketPrice = torus.price(ofToken: _params.ofToken.address);
  }

  /// Query price for 'with Token'.
  ///
  /// Set it to `null` if 'with Token' is null.
  void _refreshWithMarketPrice() {
    if (_params.withToken == null) {
      _withMarketPrice = null;

      return;
    }

    final torus = context.read<AppState>().torus();

    _withMarketPrice = torus.price(ofToken: _params.withToken.address);
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
  String _quoteText(int quote) => quote == null
      ? '-'
      : _params.withToken != null
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
    name: 'Convex Gold',
    description: 'Convex Gold Coin.',
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

class _MarketCheck extends StatelessWidget {
  final FungibleToken token;
  final Future<double> market;
  final void Function(int shares) onCreated;

  const _MarketCheck({
    Key key,
    this.token,
    this.market,
    this.onCreated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: market,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            "Getting Market...",
            style: Theme.of(context).textTheme.caption,
          );
        }

        if (snapshot.data == null) {
          return Row(
            children: [
              Text(
                "There isn't a Market yet.",
                style: Theme.of(context).textTheme.caption,
                overflow: TextOverflow.ellipsis,
              ),
              TextButton(
                child: Text('CREATE MARKET'),
                onPressed: () {
                  _create(context);
                },
              ),
            ],
          );
        }

        return Text('');
      },
    );
  }

  void _create(BuildContext context) async {
    final shares = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SafeArea(
              child: _TokenLiquidity(
                token: token,
              ),
            ),
          ),
        );
      },
    );

    if (shares != null) {
      onCreated(shares);
    }
  }
}

class _MarketPrice extends StatelessWidget {
  final ExchangeParams params;
  final Future<double> price;

  const _MarketPrice({Key key, this.params, this.price}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: price,
      builder: (context, snapshot) {
        final priceShifted = format.shiftDecimalPlace(
          snapshot.data ?? 0,
          (params.ofToken?.metadata?.decimals ?? 0) -
              (params.withToken?.metadata?.decimals ?? 0),
        );

        final withPriceText = NumberFormat().format(priceShifted);

        return Container(
          height: 50,
          child: Column(
            children: [
              Text(
                'MARKET PRICE',
                style: Theme.of(context).textTheme.overline,
              ),
              Gap(4),
              if (snapshot.connectionState == ConnectionState.waiting)
                Text('Getting Price...')
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '1 ',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    Text(
                      params.ofToken?.metadata?.symbol ?? _CVX.metadata.symbol,
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(color: Colors.black54),
                    ),
                    Icon(
                      Icons.arrow_right,
                      color: Colors.grey,
                    ),
                    Text(
                      withPriceText + ' ',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    Text(
                      (params.withToken?.metadata?.symbol ??
                          _CVX.metadata.symbol),
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(color: Colors.black54),
                    )
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TokenLiquidity extends StatefulWidget {
  final FungibleToken token;

  const _TokenLiquidity({Key key, this.token}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TokenLiquidityState();
}

class _TokenLiquidityState extends State<_TokenLiquidity> {
  int tokenAmount = 0;
  int cvxAmount = 0;
  Future<int> liquidity;

  Future<Result> balance;

  double get tokenPrice =>
      tokenAmount > 0 && cvxAmount > 0 ? tokenAmount / cvxAmount : null;

  double get cvxPrice =>
      tokenAmount > 0 && cvxAmount > 0 ? cvxAmount / tokenAmount : null;

  void initState() {
    super.initState();

    final appState = context.read<AppState>();

    final activeAddress = appState.model.activeAddress;

    balance = appState.convexClient().query(
          source: '(import convex.asset :as asset)'
              '[(balance $activeAddress) (asset/balance ${widget.token.address} $activeAddress)]',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: defaultScreenPadding,
      child: liquidity != null
          ? FutureBuilder<int>(
              future: liquidity,
              builder: (context, snapshot) {
                if (ConnectionState.waiting == snapshot.connectionState) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return Column(
                  children: [
                    Text(
                      'Gained ${snapshot.hasError ? snapshot.error : snapshot.data} liquidity shares.',
                    ),
                    Gap(20),
                    ElevatedButton(
                      child: Text('Done'),
                      onPressed: () => Navigator.pop(context, snapshot.data),
                    )
                  ],
                );
              },
            )
          : Column(
              children: <Widget>[
                Text(
                  'Add liquidity for ${widget.token.metadata.symbol}',
                  style: Theme.of(context).textTheme.headline6,
                ),
                Text(
                  'Explanatory text.',
                  style: Theme.of(context).textTheme.caption,
                ),
                Gap(40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.token.metadata.symbol} BALANCE',
                      style: Theme.of(context).textTheme.caption,
                    ),
                    Gap(8),
                    FutureBuilder<Result>(
                      future: balance,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Spinner();
                        }

                        final tokenBalance = format.formatFungibleCurrency(
                          metadata: widget.token.metadata,
                          number: (snapshot.data.value[1]),
                        );

                        return Text(
                          tokenBalance,
                          style: Theme.of(context).textTheme.bodyText2,
                        );
                      },
                    )
                  ],
                ),
                Gap(5),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount of ${widget.token.metadata.symbol}',
                    helperText: 'Helper text',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      tokenAmount = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'CVX BALANCE',
                      style: Theme.of(context).textTheme.caption,
                    ),
                    Gap(5),
                    FutureBuilder<Result>(
                      future: balance,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Spinner();
                        }

                        final userBalance =
                            format.formatCVX(snapshot.data.value[0]);

                        return Text(
                          userBalance,
                          style: Theme.of(context).textTheme.bodyText2,
                        );
                      },
                    )
                  ],
                ),
                Gap(5),
                TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: 'Amount of CVX',
                    helperText: 'Helper text',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      cvxAmount = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                Gap(30),
                Table(
                  children: [
                    TableRow(
                      children: [
                        TableCell(
                          child: Text(
                            '1 ${widget.token.metadata.symbol}',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        TableCell(
                          child: Text(
                            '=',
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        TableCell(
                          child: Text(
                            cvxPrice != null
                                ? '${NumberFormat().format(cvxPrice)} CVX'
                                : '-',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Text(
                            '1 CVX',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        TableCell(
                          child: Text(
                            '=',
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        TableCell(
                          child: Text(
                            tokenPrice != null
                                ? '$tokenPrice ${widget.token.metadata.symbol}'
                                : '-',
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Gap(30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Gap(10),
                    ElevatedButton(
                      child: Text('Confirm'),
                      onPressed: (tokenAmount != null && tokenAmount > 0) &&
                              (cvxAmount != null && cvxAmount > 0)
                          ? () {
                              setState(() {
                                liquidity = context
                                    .read<AppState>()
                                    .torus()
                                    .addLiquidity(
                                      token: widget.token.address,
                                      tokenAmount: format.readFungibleCurrency(
                                        metadata: widget.token.metadata,
                                        s: tokenAmount.toString(),
                                      ),
                                      cvxAmount: cvxAmount,
                                    );
                              });
                            }
                          : null,
                    ),
                  ],
                )
              ],
            ),
    );
  }
}
