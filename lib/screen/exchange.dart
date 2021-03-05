import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

import '../convex.dart';
import '../format.dart';
import '../logger.dart';
import '../model.dart';
import '../widget.dart';
import '../nav.dart' as nav;
import '../format.dart' as format;
import '../route.dart' as route;

class ExchangeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ExchangeParams params = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text('Exchange')),
      body: Container(
        padding: defaultScreenPadding,
        child: ExchangeScreenBody(
          params: params,
        ),
      ),
    );
  }
}

class ExchangeScreenBody extends StatefulWidget {
  final ExchangeParams params;

  const ExchangeScreenBody({
    Key key,
    this.params,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExchangeScreenBodyState(
        params: params,
      );
}

class _ExchangeScreenBodyState extends State<ExchangeScreenBody> {
  final buyIndex = 0;
  final sellIndex = 1;

  // ignore: non_constant_identifier_names
  final CVX = FungibleToken(
    address: Address(-1),
    metadata: FungibleTokenMetadata(
      name: 'CVX',
      description: 'Convex Coin',
      symbol: 'CVX',
      currencySymbol: '\$',
      decimals: 0,
    ),
  );

  ExchangeParams params;

  Future<double> marketPrice;

  Future ofTokenBalance;

  Future withTokenBalance;

  Future<Tuple2<int, int>> exchangeLiquidity;

  Future<int> quote;

  _ExchangeScreenBodyState({ExchangeParams params}) {
    this.params = params ?? ExchangeParams(action: ExchangeAction.buy);
  }

  FungibleToken _ofToken() => params.ofToken ?? CVX;

  String ofTokenAmountText(int amount) => params.ofToken == null
      ? format.formatCVX(amount)
      : format.formatFungibleCurrency(
          metadata: params.ofToken.metadata,
          number: amount,
        );

  FungibleToken _withToken() => params.withToken ?? CVX;

  String withTokenAmountText(int amount) => params.withToken == null
      ? format.formatCVX(amount)
      : format.formatFungibleCurrency(
          metadata: params.withToken.metadata,
          number: amount,
        );

  /// Returns null if there's no 'of token' selected.
  Future getOfTokenPrice(
    BuildContext context,
    ExchangeParams params,
  ) =>
      params.ofToken?.address != null
          ? context
              .read<AppState>()
              .torus()
              .price(ofToken: params.ofToken.address)
          : null;

  /// If no 'of token' is selected, it defaults to CVX,
  /// so token balance is the user's balance.
  Future getOfTokenBalance(
    BuildContext context,
    ExchangeParams params,
  ) =>
      params.ofToken?.address != null
          ? context
              .read<AppState>()
              .assetLibrary()
              .balance(asset: params.ofToken?.address)
          : context.read<AppState>().convexClient().balance();

  /// If no 'with token' is selected, it defaults to CVX,
  /// so token balance is the user's balance.
  Future getWithTokenBalance(
    BuildContext context,
    ExchangeParams params,
  ) =>
      params.withToken?.address != null
          ? context
              .read<AppState>()
              .assetLibrary()
              .balance(asset: params.withToken?.address)
          : context.read<AppState>().convexClient().balance();

  /// Returns null if there's no 'with token' selected.
  Future getWithTokenPrice(
    BuildContext context,
    ExchangeParams params,
  ) =>
      params.withToken?.address != null
          ? context
              .read<AppState>()
              .torus()
              .price(ofToken: params.withToken.address)
          : null;

  Future<int> getQuote(
    BuildContext context,
    ExchangeParams params,
  ) {
    if (params.amount == null || params.amount.isEmpty) {
      logger.d('Amount is blank. Will return null.');

      return null;
    }

    final amount = format.readFungibleCurrency(
      // 'of' is null if buying/selling CVX.
      metadata: params.ofToken?.metadata ?? CVX.metadata,
      s: params.amount,
    );

    if (params.action == ExchangeAction.buy) {
      return context.read<AppState>().torus().buyQuote(
            ofToken: params.ofToken?.address,
            amount: amount,
            withToken: params.withToken?.address,
          );
    } else {
      return context.read<AppState>().torus().sellQuote(
            ofToken: params.ofToken?.address,
            amount: amount,
            withToken: params.withToken?.address,
          );
    }
  }

  /// Returns quote formatted based on 'with Token'.
  /// If 'with Token' is selected, it will be formated using its metadata.
  /// If 'with Token' is null, it will be formatted as CVX.
  String getQuoteText(int quote) => params.withToken != null
      ? format.formatFungibleCurrency(
          metadata: params.ofToken.metadata,
          number: quote,
        )
      : format.formatCVX(quote);

  /// We want to know the liquidity pool of **of Token** and **with Token**.
  ///
  /// If a Token is missing, it's considered to be CVX.
  ///
  /// The liquidity pool of CVX is the balance of the Market (Actor).
  ///
  /// Returns a [Tuple2<int, int>] with 'of liquidity pool' and 'with liquidity pool' respectively.
  Future<Tuple2<int, int>> getExchangeLiquidity({
    BuildContext context,
    Address ofToken,
    Address withToken,
  }) async {
    // Assert that 'of Token' and 'with Token' are not the same.
    assert(ofToken != withToken);

    final appState = context.read<AppState>();

    final ofMarket = ofToken != null
        ? await appState.torus().getMarket(token: ofToken)
        : null;

    final withMarket = withToken != null
        ? await appState.torus().getMarket(token: withToken)
        : null;

    // -- Buying/selling CVX
    // 'of' is null, therefore, we are buying/selling CVX.
    if (ofToken == null) {
      final withBalance = withMarket != null
          ? await appState.assetLibrary().balance(
                asset: withToken,
                owner: withMarket,
              )
          : null;

      // 'with Market' must exist when we're buying/selling CVX.
      // If there isn't a Market, 'of balance' will be null.
      final ofBalance = withMarket != null
          ? await appState.convexClient().balance(withMarket)
          : null;

      return Tuple2<int, int>(ofBalance, withBalance);
    }

    // -- Buying/selling Tokens
    // 'of' is not null, therefore, we are buying/selling Tokens.

    final ofBalance = ofMarket != null
        ? await appState.assetLibrary().balance(
              asset: ofToken,
              owner: ofMarket,
            )
        : null;

    final isMissingWithMarket = withToken != null && withMarket == null;

    // When trading with Token, we need to query the balance of the 'of Market' too.
    // It's possible to have a 'with' Token but not have a Market for it.
    // Short circuits to null if there's a 'with' Token but doesn't have a Market for it.
    //
    // If there isn't a 'with' Token, we're exchanging for CVX, therefore,
    // we must query the balance of the 'of' Market instead.
    final withBalance = isMissingWithMarket
        ? null
        : withMarket != null
            ? await appState.assetLibrary().balance(
                  asset: withToken,
                  owner: withMarket,
                )
            : await appState.convexClient().balance(ofMarket);

    return Tuple2<int, int>(ofBalance, withBalance);
  }

  // ignore: non_constant_identifier_names
  Widget Spinner() => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );

  // ignore: non_constant_identifier_names
  Widget Balance(
    Future balance, {
    String Function(dynamic data) formatter,
  }) =>
      FutureBuilder(
        future: balance,
        builder: (context, snapshot) {
          if (ConnectionState.waiting == snapshot.connectionState) {
            return Spinner();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BALANCE',
                style: Theme.of(context).textTheme.overline,
              ),
              Gap(4),
              SelectableText(
                formatter != null
                    ? formatter(snapshot.data)
                    : snapshot.data.toString(),
                style: Theme.of(context).textTheme.bodyText2,
              )
            ],
          );
        },
      );

  // ignore: non_constant_identifier_names
  Widget MarketPrice({
    ExchangeParams params,
    Future<double> price,
  }) =>
      FutureBuilder<double>(
        future: price,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text('');
          }

          final priceShifted = format.shiftDecimalPlace(
            snapshot.data,
            (params.ofToken?.metadata?.decimals ?? 0) -
                (params.withToken?.metadata?.decimals ?? 0),
          );

          final currencySymbol = params.withToken != null
              ? params.withToken.metadata.currencySymbol
              : '';

          final priceText =
              '$currencySymbol' + NumberFormat().format(priceShifted);

          return Column(
            children: [
              Text(
                'MARKET PRICE',
                style: Theme.of(context).textTheme.overline,
              ),
              Gap(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    params.ofToken?.metadata?.symbol ?? CVX.metadata.symbol,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    Icons.arrow_right,
                    color: Colors.grey,
                  ),
                  Text(
                    params.withToken?.metadata?.symbol ?? CVX.metadata.symbol,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Gap(10),
              Text(
                priceText,
                style: Theme.of(context).textTheme.headline6,
              )
            ],
          );
        },
      );

  // ignore: non_constant_identifier_names
  Widget Quote(Future<int> quote) => FutureBuilder<int>(
        future: quote,
        builder: (context, snapshot) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                snapshot.hasData ? 'Quote' : '',
              ),
              Gap(10),
              Text(
                snapshot.hasData ? getQuoteText(snapshot.data) : '',
                style: Theme.of(context).textTheme.headline5,
              )
            ],
          );
        },
      );

  // ignore: non_constant_identifier_names
  Widget ExchangeLiquidity(
    Future<Tuple2<int, int>> exchangeLiquidity, {
    String Function(int data) ofFormatter,
    String Function(int balance) withFormatter,
  }) =>
      FutureBuilder<Tuple2<int, int>>(
        future: exchangeLiquidity,
        builder: (context, snapshot) {
          if (ConnectionState.waiting == snapshot.connectionState) {
            return Spinner();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXCHANGE LIQUIDITY',
                style: Theme.of(context).textTheme.caption,
              ),
              Gap(10),
              Table(
                children: [
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          '${params.ofToken?.metadata?.symbol ?? 'CVX'}',
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          '${params.withToken?.metadata?.symbol ?? 'CVX'}',
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          ofFormatter != null
                              ? ofFormatter(snapshot.data.item1)
                              : snapshot.data.item1.toString(),
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ),
                      TableCell(
                        child: Text(
                          withFormatter != null
                              ? withFormatter(snapshot.data.item2)
                              : snapshot.data.item2.toString(),
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      );

  void reset(ExchangeParams exchangeParams) {
    logger.d(exchangeParams.toJson());

    final appState = context.read<AppState>();

    params = exchangeParams;

    quote = getQuote(context, params);

    marketPrice = appState.torus().price(
          ofToken: exchangeParams.ofToken?.address,
          withToken: exchangeParams.withToken?.address,
        );

    ofTokenBalance = getOfTokenBalance(context, exchangeParams);

    withTokenBalance = getWithTokenBalance(context, exchangeParams);

    exchangeLiquidity = getExchangeLiquidity(
      context: context,
      ofToken: exchangeParams.ofToken?.address,
      withToken: exchangeParams.withToken?.address,
    );
  }

  @override
  void initState() {
    super.initState();

    reset(params);
  }

  @override
  Widget build(BuildContext context) {
    final gap = Gap(40);

    return SingleChildScrollView(
      child: SafeArea(
        child: FutureBuilder(
          future: marketPrice,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            final isOfPriceAvailable =
                snapshot.connectionState != ConnectionState.waiting &&
                    snapshot.data != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: actionToggle()),
                if (snapshot.data != null) ...[
                  Gap(20),
                  Center(
                    child: MarketPrice(
                      params: params,
                      price: marketPrice,
                    ),
                  ),
                  Gap(10),
                ],
                snapshot.connectionState == ConnectionState.waiting
                    ? CircularProgressIndicator()
                    : buyOrSellOf(ofTokenPrice: snapshot.data),
                if (isOfPriceAvailable) buyOrSellWith(),
                gap,
                if (isOfPriceAvailable)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: Text(actionText()),
                      onPressed:
                          (params.amount != null && params.amount.isNotEmpty)
                              ? confirm
                              : null,
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }

  String actionText() {
    switch (params.action) {
      case ExchangeAction.buy:
        return 'Buy';
      case ExchangeAction.sell:
        return 'Sell';
    }

    return '?';
  }

  String buyWithSellForText() =>
      params.action == ExchangeAction.buy ? 'With' : 'For';

  Widget actionToggle() => ToggleButtons(
        children: [
          Text('Buy'),
          Text('Sell'),
        ],
        isSelected: [
          params.action == ExchangeAction.buy,
          params.action == ExchangeAction.sell,
        ],
        onPressed: (i) {
          setState(() {
            params = params.copyWith(
              action: i == 0 ? ExchangeAction.buy : ExchangeAction.sell,
            );
          });
        },
      );

  Widget buyOrSellOf({double ofTokenPrice}) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            actionText().toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Gap(20),
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: 60, height: 60),
                child: ElevatedButton(
                  child: Text(
                    params.ofToken?.metadata?.symbol ?? CVX.metadata.symbol,
                    style: Theme.of(context).textTheme.caption.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    nav.pushSelectFungible(context).then(
                      (fungible) {
                        if (fungible != null) {
                          setState(() {
                            reset(params.copyWith(ofToken: fungible));
                          });
                        }
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.orange,
                    shape: CircleBorder(),
                  ),
                ),
              ),
              if (ofTokenPrice != null) ...[
                Gap(30),
                Text('Amount'),
                Gap(10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (s) {
                      setState(() {
                        params = params.copyWith(amount: s);

                        quote = getQuote(context, params);
                      });
                    },
                  ),
                )
              ] else ...[
                Gap(20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      child: Text('Add liquidity'),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: SafeArea(
                                  child: _TokenLiquidity(
                                    token: params.ofToken,
                                  ),
                                ),
                              ),
                            );
                          },
                        ).then((value) {
                          setState(() {
                            reset(params);
                          });
                        });
                      },
                    ),
                    Text(
                      'There is no liquidity for ${params.ofToken?.metadata?.symbol ?? ''}.',
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                )
              ]
            ],
          ),
          Gap(15),
          Row(
            children: [
              if (ofTokenBalance != null) ...[
                Balance(
                  ofTokenBalance,
                  formatter: (data) {
                    if (params.ofToken == null) {
                      return format.formatCVX(data);
                    }

                    return format.formatFungibleCurrency(
                      metadata: params.ofToken.metadata,
                      number: data,
                    );
                  },
                ),
                Gap(20),
                FutureBuilder<Tuple2<int, int>>(
                  future: exchangeLiquidity,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Spinner();
                    }

                    final ofBalance = snapshot.data?.item1;

                    final ofBalanceText = ofBalance != null
                        ? params.ofToken != null
                            ? format.formatFungibleCurrency(
                                metadata: params.ofToken.metadata,
                                number: ofBalance,
                              )
                            : format.formatCVX(ofBalance)
                        : '-';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXCHANGE LIQUIDITY',
                          style: Theme.of(context).textTheme.overline,
                        ),
                        Gap(4),
                        Text(
                          ofBalanceText,
                          style: Theme.of(context).textTheme.bodyText2,
                        )
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget buyOrSellWith() => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // With or For text.
            Text(
              buyWithSellForText().toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Gap(20),
            // Select 'with' Token.
            Row(
              children: [
                // Select 'with' Token and query price.
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: 60, height: 60),
                  child: ElevatedButton(
                    child: Text(
                      params.withToken?.metadata?.symbol ?? CVX.metadata.symbol,
                      style: Theme.of(context).textTheme.caption.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      nav.pushSelectFungible(context).then(
                        (fungible) {
                          if (fungible != null) {
                            setState(() {
                              reset(params.copyWith(withToken: fungible));
                            });
                          }
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.orange,
                      shape: CircleBorder(),
                    ),
                  ),
                ),
                Gap(30),
                if (quote != null) Quote(quote),
                Gap(30),
                // Reset 'with' Token and query price for CVX.
                if (params.withToken != null)
                  ElevatedButton(
                    child: Text(
                      'Reset',
                      style: Theme.of(context)
                          .textTheme
                          .caption
                          .copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      setState(() {
                        reset(params.resetWith());
                      });
                    },
                  ),
              ],
            ),
            Gap(15),
            // Balance, Exchange Liquidity.
            Row(
              children: [
                Balance(withTokenBalance, formatter: (data) {
                  if (params.withToken == null) {
                    return format.formatCVX(data);
                  }

                  return format.formatFungibleCurrency(
                    metadata: params.withToken.metadata,
                    number: data,
                  );
                }),
                Gap(20),
                FutureBuilder<Tuple2<int, int>>(
                  future: exchangeLiquidity,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Spinner();
                    }

                    final withBalance = snapshot.data?.item2;

                    final withBalanceText = withBalance != null
                        ? params.withToken != null
                            ? format.formatFungibleCurrency(
                                metadata: params.withToken.metadata,
                                number: withBalance,
                              )
                            : format.formatCVX(withBalance)
                        : '-';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXCHANGE LIQUIDITY',
                          style: Theme.of(context).textTheme.overline,
                        ),
                        Gap(4),
                        Text(
                          withBalanceText,
                          style: Theme.of(context).textTheme.bodyText2,
                        )
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );

  void confirm() async {
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
                  future: quote,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    // Example: Buy 1000 Token 1
                    final buyingSellingText =
                        '${actionText()} ${params.amount} ${params.ofToken.metadata.name}';

                    // Example: 1,000 CVX
                    final quoteText =
                        '${getQuoteText(snapshot.data)} ${_withToken().metadata.name}';

                    return Text(
                      '$buyingSellingText ${buyWithSellForText().toLowerCase()} $quoteText?',
                      style: Theme.of(context).textTheme.bodyText2,
                    );
                  },
                ),
              ),
              Gap(10),
              ElevatedButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
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

    final int amountOf = format.readFungibleCurrency(
      metadata: params.ofToken.metadata,
      s: params.amount,
    );

    if (params.action == ExchangeAction.buy) {
      final pricePaid = params.withToken == null
          ? appState.torus().buyTokens(
                ofToken: params.ofToken.address,
                amount: amountOf,
              )
          : appState.torus().buy(
                ofToken: params.ofToken.address,
                amount: amountOf,
                withToken: params.withToken.address,
              );

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            child: Center(
              child: FutureBuilder(
                future: pricePaid,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<int> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    logger.e(
                      'Failed to buy: ${snapshot.error}',
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
                            'Sorry. It was not possible to buy ${params.ofToken.metadata.symbol}.\n\n${snapshot.error}',
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
                              'Bought ${params.amount} ${_ofToken().metadata.symbol} for ${snapshot.data} ${_withToken().metadata.symbol}.',
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
                            reset(params.emptyAmount());
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
    } else {
      final sold = params.withToken == null
          ? appState.torus().sellTokens(
                ofToken: params.ofToken.address,
                amount: amountOf,
              )
          : appState.torus().sell(
                ofToken: params.ofToken.address,
                amount: amountOf,
                withToken: params.withToken?.address,
              );

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            child: Center(
              child: FutureBuilder<int>(
                future: sold,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<int> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    logger.e(
                      'Failed to sell: ${snapshot.error}',
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
                            'Sorry. It was not possible to sell ${params.ofToken.metadata.symbol}.\n\n${snapshot.error}',
                          ),
                        ),
                        Gap(10),
                        ElevatedButton(
                          child: const Text('Okay'),
                          onPressed: () {
                            Navigator.pop(context);

                            setState(() {
                              reset(params);
                            });
                          },
                        )
                      ],
                    );
                  }

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
                              'Sold ${params.amount} ${_ofToken().metadata.symbol} for ${snapshot.data} ${_withToken().metadata.symbol}.',
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
                            reset(params.emptyAmount());
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

  double get tokenPrice =>
      tokenAmount > 0 && cvxAmount > 0 ? tokenAmount / cvxAmount : null;

  double get cvxPrice =>
      tokenAmount > 0 && cvxAmount > 0 ? cvxAmount / tokenAmount : null;

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
                      '${snapshot.hasError ? snapshot.error : snapshot.data}',
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
                    Text(
                      '${widget.token.metadata.currencySymbol}10',
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
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
                    Text(
                      '1,000,000',
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
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
                    OutlineButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Gap(10),
                    ElevatedButton(
                      child: Text('Confirm'),
                      onPressed: tokenAmount != null &&
                              tokenAmount > 0 &&
                              cvxAmount != null &&
                              cvxAmount > 0
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
