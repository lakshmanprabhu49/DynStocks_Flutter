import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/transactions.dart' as TRANSACTIONS;
import 'package:dynstocks/models/user_info.dart' as USERINFO;
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/net_returns_for_dyn_stocks.action.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/redux/state/dyn_stocks.state.dart';
import 'package:dynstocks/static/post-market-timer.dart';
import 'package:dynstocks/static/toast_message_handler.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/screens/view_chart_for_specific_dynstock_screen.dart';
import 'package:dynstocks/views/screens/view_dynstocks_list_screen.dart';
import 'package:dynstocks/views/screens/view_transactions_screen.dart';
import 'package:dynstocks/views/widgets/bottom_navigation_bar_custom.dart';
import 'package:dynstocks/views/widgets/dyn_stocks_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock/wakelock.dart';

class ViewSpecificDynStockScreen extends StatefulWidget {
  String currentDynStockCode;
  ViewSpecificDynStockScreen({Key? key, required this.currentDynStockCode})
      : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _ViewSpecificDynStockScreenState createState() =>
      _ViewSpecificDynStockScreenState(
          currentDynStockCode: currentDynStockCode);
}

class _ViewSpecificDynStockScreenState extends State<ViewSpecificDynStockScreen>
    with RouteAware {
  String currentDynStockCode;
  DynStock? currentDynStock;
  String currentDynStockTimePeriod = '1h';
  bool isTimedTickerFetchStarted = false;
  List<String> dynStockTimePeriod =
      List.from(['1h', '1d', '1w', '1m', '3m', '6m', '1y', 'All']);

  EDSTPUnit currentDSTPUnit = EDSTPUnit.Price;
  Map<EDSTPUnit, String> DSTPUnitMap = Map();
  String currentNoOfStocks = '0';
  String currentBTP = '0.0';
  double netReturnsForDynStocks = 0.0;
  String currentSTP = '0.0';
  String currentTolerance = '1.0';
  bool deleteButtonDisabled = true;
  EChoice stallTransactions = EChoice.No;
  bool shouldLoadInitialValues = true;
  bool errorMessageShown = false;
  _ViewSpecificDynStockScreenState(
      {Key? key, required this.currentDynStockCode});
  bool reload = false;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    DSTPUnitMap[EDSTPUnit.Price] = 'Price';
    DSTPUnitMap[EDSTPUnit.Percentage] = 'Percentage';
  }

  // This function starts the periodic timer for the ticker data action
  // If the ticker timer hasn't started , there is an explicit timer for the screen which runs,
  // till the ticker timer is started
  void startPeriodicTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        PostMarketTimer.startPostMarketTimer(context);
        bool timerStarted = TimedTickerCall?.startTimedTickerCallForDynStocks(
          context,
        );
        if (timerStarted) {
          setState(() {
            isTimedTickerFetchStarted = true;
          });
          timer.cancel();
        }
      }
    });
  }

  // Stops the periodic timer, possibly invoked when the screen goes out of focus
  void stopPeriodicTimer() {
    TimedTickerCall.stopTimedTickerCallForDynStocks();
  }

  @override
  void didPop() {
    stopPeriodicTimer();
    super.didPop();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    startPeriodicTimer();
  }

  @override
  void didPush() {
    super.didPush();
    shouldLoadInitialValues = true;
    startPeriodicTimer();
  }

  @override
  void didPushNext() {
    stopPeriodicTimer();
    super.didPushNext();
  }

  @override
  void dispose() {
    stopPeriodicTimer();
    super.dispose();
  }

  void loadInitialValuesForDynStock(DynStock dynStock) {
    currentDSTPUnit =
        dynStock.DSTPUnit == 'Price' ? EDSTPUnit.Price : EDSTPUnit.Percentage;
    currentNoOfStocks = dynStock.noOfStocks.toString();
    currentBTP = currentDSTPUnit == EDSTPUnit.Price
        ? dynStock.BTPr.toString()
        : dynStock.BTPe.toString();
    currentSTP = currentDSTPUnit == EDSTPUnit.Price
        ? dynStock.STPr.toString()
        : dynStock.STPe.toString();
    currentTolerance = dynStock.tolerance.toString();
    stallTransactions = dynStock.stallTransactions ? EChoice.Yes : EChoice.No;
    DateTime lastTransactionTime =
        DateTime.fromMillisecondsSinceEpoch(dynStock.lastTransactionTime!.date);
    DateTime now = DateTime.now();
    DateTime secondNextDayOfTransaction =
        lastTransactionTime.add(Duration(days: 2));
    secondNextDayOfTransaction = secondNextDayOfTransaction.subtract(Duration(
        minutes: lastTransactionTime.minute,
        hours: lastTransactionTime.hour,
        seconds: lastTransactionTime.second));
    bool stockMarketClosedCondition = (now.hour < 9) ||
        now.hour >= 16 ||
        (now.hour == 9 && now.minute < 15) ||
        (now.hour == 15 && now.minute > 30) ||
        (now.weekday > 5);
    if (((secondNextDayOfTransaction.compareTo(now) > 0 &&
                dynStock.stockType == EStockType.BE.name) &&
            dynStock.lastTransactionType == 'BUY') ||
        stockMarketClosedCondition) {
      deleteButtonDisabled = true;
    } else {
      deleteButtonDisabled = false;
    }
    StoreProvider.of<AppState>(context).dispatch(GetNetReturnsForDynStockAction(
        userId: userId, dynStockId: dynStock.dynStockId.uuid, period: '1h'));
  }

  Future<String?> showDeleteDialog(DynStock currentDynStock) {
    if (deleteButtonDisabled) {
      return showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            'Cannot delete ${currentDynStockCode}',
            style: GoogleFonts.outfit(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: AccentColors.red1,
            ),
          ),
          content: Text(
            'You cannot delete this dynstock, as it\'s a BE stock or market is closed currently',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AccentColors.yellow1,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context, 'Close'),
              child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Text(
                    'Close',
                    style: GoogleFonts.lusitana(
                      fontSize: 15,
                      color: AccentColors.red1,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
            )
          ],
        ),
      );
    } else {
      return showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            'Delete ${currentDynStockCode}',
            style: GoogleFonts.outfit(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: AccentColors.red1,
            ),
          ),
          content: Text(
            'Are you sure you want to delete the DynStock? This will sell all the stocks held for this DynStock',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AccentColors.yellow1,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.lusitana(
                      fontSize: 15,
                      color: AccentColors.red1,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  AccentColors.red1,
                ),
              ),
              onPressed: () {
                StoreProvider.of<AppState>(context)
                    .dispatch(DeleteDynStockAction(
                  userId: userId,
                  stockCode: currentDynStock.stockCode,
                  dynStockId: currentDynStock.dynStockId.uuid,
                ));
                setState(() {
                  errorMessageShown = false;
                });
                Navigator.pop(context, 'Delete');
                Route newRoute = MaterialPageRoute(
                    builder: (context) => ViewDynStocksListScreen());
                Navigator.pop(context);
              },
              child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.lusitana(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
            ),
          ],
        ),
      );
    }
  }

  String userId = appStore.state.userId;

  Future<String?> showForceTransactionDialog(DynStock currentDynStock) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Force ${currentDynStock.lastTransactionType == ETransactionType.BUY.name ? ETransactionType.SELL.name : ETransactionType.BUY.name}?',
          style: GoogleFonts.outfit(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AccentColors.red1,
          ),
        ),
        content: Text(
          'Are you sure you want to force ${currentDynStock.lastTransactionType == ETransactionType.BUY.name ? ETransactionType.SELL.name : ETransactionType.BUY.name} the stock at the market price?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AccentColors.yellow1,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                Colors.white,
              ),
            ),
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.lusitana(
                    fontSize: 15,
                    color: AccentColors.red1,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                AccentColors.red1,
              ),
            ),
            onPressed: () {
              if (mounted) {
                if (currentDynStock.lastTransactionType ==
                    ETransactionType.BUY.name) {
                  StoreProvider.of<AppState>(context).dispatch(
                      CreateTransactionAction(
                          userId: userId,
                          instrumentToken: currentDynStock.instrumentToken,
                          dynStockId: currentDynStock.dynStockId.uuid,
                          stockCode: currentDynStock.stockCode,
                          body: TRANSACTIONS.TransactionBody(
                              transactionId:
                                  DateTime.now().microsecond.toString(),
                              stockCode: currentDynStock.stockCode,
                              type: 'SELL',
                              stockPrice: 0,
                              noOfStocks:
                                  currentDynStock.stocksAvailableForTrade),
                          stockOrderType: EStockOrderType.Market.name,
                          forcedTransaction: true));
                  errorMessageShown = false;
                } else {
                  StoreProvider.of<AppState>(context).dispatch(
                      CreateTransactionAction(
                          userId: userId,
                          instrumentToken: currentDynStock.instrumentToken,
                          dynStockId: currentDynStock.dynStockId.uuid,
                          stockCode: currentDynStock.stockCode,
                          body: TRANSACTIONS.TransactionBody(
                              transactionId:
                                  DateTime.now().microsecond.toString(),
                              stockCode: currentDynStock.stockCode,
                              type: 'BUY',
                              stockPrice: 0,
                              noOfStocks: currentDynStock.noOfStocks),
                          stockOrderType: EStockOrderType.Market.name,
                          forcedTransaction: true));
                }
              }
            },
            child: Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  currentDynStock.lastTransactionType ==
                          ETransactionType.BUY.name
                      ? 'Force Sell'
                      : 'Force Buy',
                  style: GoogleFonts.lusitana(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize;
    Wakelock.enabled.then((value) {
      if (!value) {
        Wakelock.enable();
      }
    });
    DateTime now = DateTime.now();
    if ((now.hour < 9) || (now.hour == 9 && now.hour < 15)) {
      Timer.periodic(Duration(seconds: 1), (timer) {
        DateTime currentTime = DateTime.now();
        if (currentTime.hour == 9 && now.hour >= 15) {
          setState(() {
            reload = true;
          });
          timer.cancel();
        }
      });
    }
    screenSize = MediaQuery.of(context).size;
    if (appStore.state.allDynStocks.deleteFailed && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.allDynStocks.error}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    if (appStore.state.allDynStocks.updateFailed && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.allDynStocks.error}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    if (appStore.state.allDynStocks.loaded &&
        !appStore.state.allDynStocks.loading &&
        appStore.state.allDynStocks.data.isNotEmpty) {
      DynStock dynStock = appStore.state.allDynStocks.data
          .firstWhere((dynStock) => dynStock.stockCode == currentDynStockCode);
      currentDynStock = dynStock;
      if (shouldLoadInitialValues) {
        loadInitialValuesForDynStock(dynStock);
        shouldLoadInitialValues = false;
      }
    }
    if (appStore.state.netReturnsForDynStock.loadFailed && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.allDynStocks.error}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    if (appStore.state.transactionsCreateState.error != null &&
        !errorMessageShown) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.allTransactions.error}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    if (appStore.state.netReturnsForDynStock.loaded &&
        !appStore.state.netReturnsForDynStock.loading) {
      setState(() {
        netReturnsForDynStocks = appStore.state.netReturnsForDynStock.data;
      });
    }

    return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: StoreConnector<AppState, AppState>(
            onDidChange: (previousState, state) {
              if (state.allDynStocks.deleteFailed && !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.allDynStocks.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
              if (state.netReturnsForDynStock.loadFailed &&
                  !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.allDynStocks.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
              if (state.netReturnsForDynStock.loaded &&
                  !state.netReturnsForDynStock.loading) {
                setState(() {
                  netReturnsForDynStocks = state.netReturnsForDynStock.data;
                });
              }
              if (state.allDynStocks.updateFailed && !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.allDynStocks.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
            },
            converter: ((store) => store.state),
            builder: (context, state) {
              DynStock currentDynStock = state.allDynStocks.data.firstWhere(
                  (element) => element.stockCode == currentDynStockCode);
              return Container(
                width: screenSize.width * 0.75,
                height: screenSize.height,
                decoration: BoxDecoration(color: PaletteColors.blue3),
                child: Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: Form(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                        Text(
                          'Edit your DynStock',
                          style: GoogleFonts.outfit(
                            color: PaletteColors.blue2,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                            height: screenSize.height * 0.75,
                            child: SingleChildScrollView(
                              child: Column(children: [
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                                    decoration:
                                        BoxDecoration(color: Colors.white),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'DSTP Unit',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.lusitana(
                                              fontSize: 23,
                                              color: PaletteColors.blue2),
                                        )
                                      ]),
                                      Container(
                                          margin:
                                              EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: PaletteColors.blue3),
                                          padding:
                                              EdgeInsets.fromLTRB(10, 0, 10, 0),
                                          child: DropdownButton(
                                              style: GoogleFonts.overlock(
                                                  color: PaletteColors.purple1,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                              isExpanded: true,
                                              alignment:
                                                  AlignmentDirectional.center,
                                              dropdownColor:
                                                  PaletteColors.blue3,
                                              value: currentDSTPUnit.toString(),
                                              items:
                                                  DSTPUnitMap.entries.map((e) {
                                                return DropdownMenuItem<String>(
                                                    value: e.key.toString(),
                                                    child: Text(
                                                      e.value,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ));
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  currentDSTPUnit = EDSTPUnit
                                                      .values
                                                      .firstWhere((element) =>
                                                          element.toString() ==
                                                          newValue);
                                                });
                                              })),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                                    decoration:
                                        BoxDecoration(color: Colors.white),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'Number of Stocks',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.lusitana(
                                              fontSize: 23,
                                              color: PaletteColors.blue2),
                                        )
                                      ]),
                                      Container(
                                          margin:
                                              EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: PaletteColors.blue3),
                                          padding:
                                              EdgeInsets.fromLTRB(10, 0, 10, 0),
                                          child: (TextFormField(
                                            initialValue: currentNoOfStocks,
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please enter a value';
                                              }
                                              if (value.contains('.')) {
                                                return 'No decimal places allowed';
                                              }
                                              return null;
                                            },
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            onChanged: (newValue) =>
                                                setState(() {
                                              currentNoOfStocks = newValue;
                                            }),
                                          ))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                                    decoration:
                                        BoxDecoration(color: Colors.white),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          currentDSTPUnit == EDSTPUnit.Price
                                              ? 'BTPr'
                                              : 'BTPe',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.lusitana(
                                              fontSize: 23,
                                              color: PaletteColors.blue2),
                                        )
                                      ]),
                                      Container(
                                          margin:
                                              EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: PaletteColors.blue3),
                                          padding:
                                              EdgeInsets.fromLTRB(10, 0, 10, 0),
                                          child: (TextFormField(
                                              initialValue: currentBTP,
                                              keyboardType:
                                                  TextInputType.number,
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Please enter a value';
                                                }
                                                if (currentDSTPUnit ==
                                                        EDSTPUnit.Percentage &&
                                                    (double.parse(value
                                                                as String) >
                                                            100.0 ||
                                                        double.parse(value
                                                                as String) <
                                                            0.0)) {
                                                  return 'Please enter a valid percentage';
                                                }
                                                if (currentDSTPUnit ==
                                                        EDSTPUnit.Price &&
                                                    value.split('.').length >
                                                        2) {
                                                  return 'Please enter a valid decimal number';
                                                }
                                                return null;
                                              },
                                              onChanged: (newValue) =>
                                                  setState(() {
                                                    currentBTP = newValue;
                                                  })))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                                    decoration:
                                        BoxDecoration(color: Colors.white),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          currentDSTPUnit == EDSTPUnit.Price
                                              ? 'STPr'
                                              : 'STPe',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.lusitana(
                                              fontSize: 23,
                                              color: PaletteColors.blue2),
                                        )
                                      ]),
                                      Container(
                                          margin:
                                              EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: PaletteColors.blue3),
                                          padding:
                                              EdgeInsets.fromLTRB(10, 0, 10, 0),
                                          child: (TextFormField(
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Please enter a value';
                                                }
                                                if (currentDSTPUnit ==
                                                        EDSTPUnit.Percentage &&
                                                    (double.parse(value
                                                                as String) >
                                                            100.0 ||
                                                        double.parse(value
                                                                as String) <
                                                            0.0)) {
                                                  return 'Please enter a valid percentage';
                                                }
                                                if (currentDSTPUnit ==
                                                        EDSTPUnit.Price &&
                                                    value.split('.').length >
                                                        2) {
                                                  return 'Please enter a valid decimal number';
                                                }
                                                return null;
                                              },
                                              initialValue: currentSTP,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (newValue) =>
                                                  setState(() {
                                                    currentSTP = newValue;
                                                  })))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                                    decoration:
                                        BoxDecoration(color: Colors.white),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'Tolerance (amount)',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.lusitana(
                                              fontSize: 23,
                                              color: PaletteColors.blue2),
                                        )
                                      ]),
                                      Container(
                                          margin:
                                              EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: PaletteColors.blue3),
                                          padding:
                                              EdgeInsets.fromLTRB(10, 0, 10, 0),
                                          child: (TextFormField(
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Please enter a value';
                                                }
                                                if (currentDSTPUnit ==
                                                        EDSTPUnit.Percentage &&
                                                    (double.parse(value
                                                                as String) >
                                                            100.0 ||
                                                        double.parse(value
                                                                as String) <
                                                            0.0)) {
                                                  return 'Please enter a valid percentage';
                                                }
                                                if (currentDSTPUnit ==
                                                        EDSTPUnit.Price &&
                                                    value.split('.').length >
                                                        2) {
                                                  return 'Please enter a valid decimal number';
                                                }
                                                return null;
                                              },
                                              initialValue: currentTolerance,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (newValue) =>
                                                  setState(() {
                                                    currentTolerance = newValue;
                                                  })))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                                    decoration:
                                        BoxDecoration(color: Colors.white),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'Stall Transactions',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.lusitana(
                                              fontSize: 23,
                                              color: PaletteColors.blue2),
                                        )
                                      ]),
                                      Container(
                                          margin:
                                              EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: PaletteColors.blue3),
                                          padding:
                                              EdgeInsets.fromLTRB(10, 0, 10, 0),
                                          child: DropdownButton(
                                              style: GoogleFonts.overlock(
                                                  color: PaletteColors.purple1,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                              isExpanded: true,
                                              alignment:
                                                  AlignmentDirectional.center,
                                              dropdownColor:
                                                  PaletteColors.blue3,
                                              value: stallTransactions.name
                                                  .toString(),
                                              items: EChoice.values.map((e) {
                                                return DropdownMenuItem<String>(
                                                    value: e.name.toString(),
                                                    child: Text(
                                                      e.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ));
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  stallTransactions = EChoice
                                                      .values
                                                      .firstWhere((element) =>
                                                          element.name ==
                                                          newValue);
                                                });
                                              })),
                                    ])),
                              ]),
                            )),
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 15, 0, 0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      Scaffold.of(context).closeDrawer();
                                    },
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15))),
                                        fixedSize: MaterialStateProperty.all(
                                            Size(screenSize.width * 0.3, 50)),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.white)),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.outfit(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                        color: PaletteColors.blue2,
                                      ),
                                    )),
                                ElevatedButton(
                                    onPressed: () {
                                      if (state.allDynStocks.data.isNotEmpty) {
                                        DynStock dynStockToBeUpdated =
                                            state.allDynStocks.data.firstWhere(
                                          (element) =>
                                              element.stockCode ==
                                              currentDynStockCode,
                                        );
                                        {
                                          StoreProvider.of<AppState>(context)
                                              .dispatch(UpdateDynStockAction(
                                                  userId: userId,
                                                  dynStockId:
                                                      dynStockToBeUpdated
                                                          .dynStockId.uuid,
                                                  body: DynStockBody(
                                                    stockCode:
                                                        dynStockToBeUpdated
                                                            .stockCode,
                                                    instrumentToken:
                                                        dynStockToBeUpdated
                                                            .instrumentToken,
                                                    stockName:
                                                        dynStockToBeUpdated
                                                            .stockName,
                                                    exchange:
                                                        dynStockToBeUpdated
                                                            .exchange,
                                                    stockType:
                                                        dynStockToBeUpdated
                                                            .stockType,
                                                    yFinStockCode:
                                                        dynStockToBeUpdated
                                                            .yFinStockCode,
                                                    noOfStocks: int.parse(
                                                        currentNoOfStocks),
                                                    DSTPUnit: currentDSTPUnit ==
                                                            EDSTPUnit.Price
                                                        ? 'Price'
                                                        : 'Percentage',
                                                    BTPr: currentDSTPUnit ==
                                                            EDSTPUnit.Price
                                                        ? double.parse(
                                                            currentBTP)
                                                        : 0.0,
                                                    BTPe: currentDSTPUnit ==
                                                            EDSTPUnit.Percentage
                                                        ? double.parse(
                                                            currentBTP)
                                                        : 0.0,
                                                    STPr: currentDSTPUnit ==
                                                            EDSTPUnit.Price
                                                        ? double.parse(
                                                            currentSTP)
                                                        : 0.0,
                                                    STPe: currentDSTPUnit ==
                                                            EDSTPUnit.Percentage
                                                        ? double.parse(
                                                            currentSTP)
                                                        : 0.0,
                                                    stallTransactions:
                                                        stallTransactions ==
                                                                EChoice.Yes
                                                            ? true
                                                            : false,
                                                    tolerance: double.parse(
                                                        currentTolerance),
                                                  )));
                                          setState(() {
                                            errorMessageShown = false;
                                          });

                                          Scaffold.of(context).closeDrawer();
                                        }
                                      }
                                    },
                                    child: Text(
                                      'Update',
                                      style: GoogleFonts.outfit(
                                          fontSize: 23,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15))),
                                        fixedSize: MaterialStateProperty.all(
                                            Size(screenSize.width * 0.3, 50)),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                PaletteColors.blue2)))
                              ]),
                        )
                      ])),
                ),
              );
            }),
        body: StoreConnector<AppState, AppState>(
            onDidChange: (previousState, state) {
              if (state.allDynStocks.deleteFailed && !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.allDynStocks.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
              if (state.transactionsCreateState.error != null &&
                  !errorMessageShown) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.allTransactions.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
              if (state.netReturnsForDynStock.loadFailed &&
                  !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.allDynStocks.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
              if (state.netReturnsForDynStock.loaded &&
                  !state.netReturnsForDynStock.loading) {
                setState(() {
                  netReturnsForDynStocks = state.netReturnsForDynStock.data;
                });
              }
              if (state.allDynStocks.updateFailed && !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.allDynStocks.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
            },
            converter: ((store) => store.state),
            builder: (context, state) {
              DynStock? currentDynStock = state.allDynStocks.data.firstWhere(
                  (element) => element.stockCode == currentDynStockCode,
                  orElse: () => DynStock(
                      userId: Id(uuid: appStore.state.userId),
                      dynStockId: Id(uuid: ''),
                      stockCode: '',
                      yFinStockCode: '',
                      stockName: '',
                      exchange: '',
                      stockType: '',
                      instrumentToken: '',
                      DSTPUnit: '',
                      tolerance: 1.0,
                      noOfStocks: 0));
              if (currentDynStock.dynStockId.uuid.isNotEmpty) {
                return SingleChildScrollView(
                    child: Container(
                        child: Column(
                  children: [
                    Container(
                        margin: EdgeInsets.fromLTRB(10, 30, 10, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                                flex: 1,
                                child: Container(
                                    margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: ButtonTheme(
                                        height: 25,
                                        minWidth: 25,
                                        child: TextButton(
                                          style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.transparent),
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.transparent)),
                                          child: Icon(
                                            Icons.arrow_back,
                                            size: 35,
                                            color: Colors.black,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        )))),
                            Flexible(
                                flex: 2,
                                child: Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                    child: Column(children: [
                                      Text(
                                        currentDynStockCode,
                                        style: GoogleFonts.outfit(
                                          fontSize: 30 /
                                              int.parse((1 +
                                                      (currentDynStockCode
                                                                  .length /
                                                              10)
                                                          .toInt())
                                                  .toString()),
                                          color: PaletteColors.blue2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (currentDynStock.stallTransactions)
                                        (Container(
                                            margin: EdgeInsets.fromLTRB(
                                                10, 0, 0, 0),
                                            padding: EdgeInsets.fromLTRB(
                                                10, 5, 10, 5),
                                            decoration: BoxDecoration(
                                                color: AccentColors.red2),
                                            child: Text(
                                              'Stalled',
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                color: AccentColors.red1,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )))
                                    ]))),
                            Flexible(
                                flex: 1,
                                child: Container(
                                    margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: ButtonTheme(
                                        height: 25,
                                        minWidth: 25,
                                        child: TextButton(
                                          style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.transparent),
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.transparent)),
                                          child: Icon(
                                            Icons.delete_forever_rounded,
                                            size: 35,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              showDeleteDialog(currentDynStock),
                                        )))),
                          ],
                        )),
                    Container(
                      child: Column(children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  child: Container(
                                      width: screenSize.width * 0.35,
                                      height: screenSize.height * 0.1,
                                      decoration: BoxDecoration(
                                          color: PaletteColors.blue3,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currentDynStock.DSTPUnit,
                                            style: GoogleFonts.daysOne(
                                              color: PaletteColors.blue2,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'DSTP Unit',
                                            style: GoogleFonts.outfit(
                                              color: PaletteColors.blue4,
                                              fontSize: 15,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Container(
                                      width: screenSize.width * 0.35,
                                      height: screenSize.height * 0.1,
                                      decoration: BoxDecoration(
                                          color: PaletteColors.blue3,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currentDynStock.noOfStocks
                                                .toString(),
                                            style: GoogleFonts.daysOne(
                                              color: PaletteColors.blue2,
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Stocks',
                                            style: GoogleFonts.outfit(
                                              color: PaletteColors.blue4,
                                              fontSize: 15,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                              ]),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  child: Container(
                                      width: screenSize.width * 0.35,
                                      height: screenSize.height * 0.075,
                                      decoration: BoxDecoration(
                                          color: PaletteColors.purple2,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (currentDynStock.DSTPUnit ==
                                              'Price')
                                            (Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.currency_rupee,
                                                  color: PaletteColors.blue2,
                                                  size: 20,
                                                ),
                                                Text(
                                                  currentDynStock.STPr
                                                      .toStringAsFixed(2),
                                                  style: GoogleFonts.daysOne(
                                                    color: PaletteColors.blue2,
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              ],
                                            )),
                                          if (currentDynStock.DSTPUnit ==
                                              'Percentage')
                                            (Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  currentDynStock.STPe
                                                      .toStringAsFixed(2),
                                                  style: GoogleFonts.daysOne(
                                                    color: PaletteColors.blue2,
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.percent,
                                                  color: PaletteColors.blue2,
                                                  size: 20,
                                                ),
                                              ],
                                            )),
                                          Text(
                                            currentDynStock.DSTPUnit == 'Price'
                                                ? 'STPr'
                                                : 'STPe',
                                            style: GoogleFonts.outfit(
                                              color: PaletteColors.blue4,
                                              fontSize: 15,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Container(
                                      width: screenSize.width * 0.35,
                                      height: screenSize.height * 0.075,
                                      decoration: BoxDecoration(
                                          color: PaletteColors.purple2,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (currentDynStock.DSTPUnit ==
                                              'Price')
                                            (Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.currency_rupee,
                                                  color: PaletteColors.blue2,
                                                  size: 20,
                                                ),
                                                Text(
                                                  currentDynStock.BTPr
                                                      .toStringAsFixed(2),
                                                  style: GoogleFonts.daysOne(
                                                    color: PaletteColors.blue2,
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              ],
                                            )),
                                          if (currentDynStock.DSTPUnit ==
                                              'Percentage')
                                            (Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  currentDynStock.BTPe
                                                      .toStringAsFixed(2),
                                                  style: GoogleFonts.daysOne(
                                                    color: PaletteColors.blue2,
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.percent,
                                                  color: PaletteColors.blue2,
                                                  size: 20,
                                                ),
                                              ],
                                            )),
                                          Text(
                                            currentDynStock.DSTPUnit == 'Price'
                                                ? 'BTPr'
                                                : 'BTPe',
                                            style: GoogleFonts.outfit(
                                              color: PaletteColors.blue4,
                                              fontSize: 15,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                              ]),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  child: Container(
                                      width: screenSize.width * 0.35,
                                      height: screenSize.height * 0.075,
                                      decoration: BoxDecoration(
                                          color: PaletteColors.blue3,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currentDynStock.exchange,
                                            style: GoogleFonts.daysOne(
                                              color: PaletteColors.blue2,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Exchange',
                                            style: GoogleFonts.outfit(
                                              color: PaletteColors.blue4,
                                              fontSize: 15,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Container(
                                      width: screenSize.width * 0.35,
                                      height: screenSize.height * 0.075,
                                      decoration: BoxDecoration(
                                          color: PaletteColors.blue3,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currentDynStock.stockType
                                                .toString(),
                                            style: GoogleFonts.daysOne(
                                              color: PaletteColors.blue2,
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Stock Type',
                                            style: GoogleFonts.outfit(
                                              color: PaletteColors.blue4,
                                              fontSize: 15,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                              ]),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  child: Container(
                                      width: screenSize.width * 0.35,
                                      height: screenSize.height * 0.075,
                                      decoration: BoxDecoration(
                                          color: PaletteColors.purple2,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currentDynStock.tolerance
                                                .toStringAsFixed(2),
                                            style: GoogleFonts.daysOne(
                                              color: PaletteColors.blue2,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Tolerance (amount)',
                                            style: GoogleFonts.outfit(
                                              color: PaletteColors.blue4,
                                              fontSize: 15,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                                Container(
                                  child: Container(
                                      width: screenSize.width * 0.35,
                                      height: screenSize.height * 0.075,
                                      decoration: BoxDecoration(
                                          color: PaletteColors.purple2,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currentDynStock.lastTradedPrice
                                                .toStringAsFixed(2),
                                            style: GoogleFonts.daysOne(
                                              color: PaletteColors.blue2,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Last Traded Price',
                                            style: GoogleFonts.outfit(
                                              color: PaletteColors.blue4,
                                              fontSize: 15,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                              ]),
                        ),
                      ]),
                    ),
                    if (state.allTickerData.data.isNotEmpty)
                      Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                child: Container(
                                    width: screenSize.width * 0.35,
                                    height: screenSize.height * 0.075,
                                    decoration: BoxDecoration(
                                        color: PaletteColors.blue3,
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${currentDynStock.lastTransactionType} ',
                                          style: GoogleFonts.daysOne(
                                            color: PaletteColors.blue2,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Last Transaction Type',
                                          style: GoogleFonts.outfit(
                                            color: PaletteColors.blue4,
                                            fontSize: 12,
                                          ),
                                        )
                                      ],
                                    )),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15)),
                                child: Container(
                                    width: screenSize.width * 0.35,
                                    height: screenSize.height * 0.075,
                                    decoration: BoxDecoration(
                                        color: PaletteColors.blue3,
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${currentDynStock.lastTransactionType == 'BUY' ? (state.allTickerData.data[currentDynStockCode]?.currentLocalMaximumPrice.toStringAsFixed(2) ?? '') : (state.allTickerData.data[currentDynStockCode]?.currentLocalMinimumPrice.toStringAsFixed(2))}',
                                          style: GoogleFonts.daysOne(
                                            color: PaletteColors.blue2,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${currentDynStock.lastTransactionType == 'BUY' ? 'CLMaP' : 'CLMiP'}',
                                          style: GoogleFonts.outfit(
                                            color: PaletteColors.blue4,
                                            fontSize: 15,
                                          ),
                                        )
                                      ],
                                    )),
                              ),
                            ]),
                        (Container(
                            width: screenSize.width * 0.9,
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                      padding:
                                          EdgeInsets.fromLTRB(10, 10, 10, 10),
                                      decoration: BoxDecoration(
                                          color: PaletteColors.blue3,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Row(children: [
                                        Column(children: [
                                          Row(children: [
                                            Icon(
                                              Icons.currency_rupee,
                                              size: 35,
                                              color: PaletteColors.blue2,
                                            ),
                                            Text(
                                              state
                                                          .allTickerData
                                                          .data[
                                                              currentDynStockCode]
                                                          ?.price
                                                          .currentPrice !=
                                                      null
                                                  ? state
                                                      .allTickerData
                                                      .data[
                                                          currentDynStockCode]!
                                                      .price
                                                      .currentPrice!
                                                      .toStringAsFixed(2)
                                                  : '',
                                              style: GoogleFonts.overlock(
                                                  fontSize: 30,
                                                  color: PaletteColors.blue2,
                                                  fontWeight: FontWeight.bold),
                                            )
                                          ]),
                                          Container(
                                            child: Text(
                                              'Stock Price',
                                              style: GoogleFonts.overlock(
                                                fontSize: 15,
                                                color: PaletteColors.blue4,
                                              ),
                                            ),
                                          )
                                        ]),
                                        Container(
                                          margin:
                                              EdgeInsets.fromLTRB(10, 0, 10, 0),
                                          child: Column(children: [
                                            Text(
                                              (state
                                                                  .allTickerData
                                                                  .data[
                                                                      currentDynStockCode]
                                                                  ?.priceChange
                                                                  .regularMarketChange !=
                                                              null &&
                                                          state
                                                                  .allTickerData
                                                                  .data[
                                                                      currentDynStockCode]!
                                                                  .priceChange
                                                                  .regularMarketChange! >
                                                              0
                                                      ? '+'
                                                      : '') +
                                                  (state
                                                              .allTickerData
                                                              .data[
                                                                  currentDynStockCode]
                                                              ?.priceChange
                                                              .regularMarketChange !=
                                                          null
                                                      ? state
                                                          .allTickerData
                                                          .data[
                                                              currentDynStockCode]!
                                                          .priceChange
                                                          .regularMarketChange!
                                                          .toStringAsFixed(2)
                                                      : ''),
                                              style: GoogleFonts.lusitana(
                                                  fontSize: 17,
                                                  color: state
                                                                  .allTickerData
                                                                  .data[
                                                                      currentDynStockCode]
                                                                  ?.priceChange
                                                                  .regularMarketChange !=
                                                              null &&
                                                          state
                                                                  .allTickerData
                                                                  .data[
                                                                      currentDynStockCode]!
                                                                  .priceChange
                                                                  .regularMarketChange! >
                                                              0
                                                      ? AccentColors.green1
                                                      : AccentColors.red1),
                                            ),
                                            Text(
                                              '(${state.allTickerData.data[currentDynStockCode]?.priceChange.regularMarketChangePercent != null && state.allTickerData.data[currentDynStockCode]!.priceChange.regularMarketChangePercent! > 0 ? '+' : ''}${state.allTickerData.data[currentDynStockCode]!.priceChange.regularMarketChangePercent != null ? state.allTickerData.data[currentDynStockCode]!.priceChange.regularMarketChangePercent!.toStringAsFixed(2) : ''} %)',
                                              style: GoogleFonts.lusitana(
                                                  fontSize: 15,
                                                  color: state
                                                                  .allTickerData
                                                                  .data[
                                                                      currentDynStockCode]
                                                                  ?.priceChange
                                                                  .regularMarketChangePercent !=
                                                              null &&
                                                          state
                                                                  .allTickerData
                                                                  .data[
                                                                      currentDynStockCode]!
                                                                  .priceChange
                                                                  .regularMarketChangePercent! >
                                                              0
                                                      ? AccentColors.green1
                                                      : AccentColors.red1),
                                            )
                                          ]),
                                        )
                                      ]))
                                ])))
                      ]),
                    Container(
                      margin: EdgeInsets.fromLTRB(20, 10, 20, 0),
                      width: screenSize.width,
                      height: 50,
                      padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                      decoration: BoxDecoration(
                          color: PaletteColors.blue3,
                          borderRadius: BorderRadius.circular(20)),
                      child: ListView.separated(
                          separatorBuilder: (context, index) => SizedBox(
                                width: 10,
                                height: 10,
                              ),
                          scrollDirection: Axis.horizontal,
                          itemCount: dynStockTimePeriod.length,
                          itemBuilder: ((context, index) {
                            return Container(
                                width: 55,
                                height: 25,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular((25))),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                      shape: MaterialStateProperty.all<
                                              OutlinedBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15))),
                                      fixedSize: MaterialStateProperty.all(
                                          Size(30, 30)),
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              currentDynStockTimePeriod ==
                                                      dynStockTimePeriod[index]
                                                  ? PaletteColors.blue2
                                                  : PaletteColors.blue3)),
                                  child: Text(
                                    dynStockTimePeriod[index],
                                    style: GoogleFonts.lusitana(
                                      color: currentDynStockTimePeriod ==
                                              dynStockTimePeriod[index]
                                          ? Colors.white
                                          : PaletteColors.blue2,
                                      fontSize: 15,
                                    ),
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.center,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      currentDynStockTimePeriod =
                                          dynStockTimePeriod[index];
                                    });
                                    StoreProvider.of<AppState>(context)
                                        .dispatch(
                                            GetNetReturnsForDynStockAction(
                                                userId: userId,
                                                dynStockId: currentDynStock
                                                    .dynStockId.uuid,
                                                period:
                                                    currentDynStockTimePeriod));
                                    setState(() {
                                      errorMessageShown = false;
                                    });
                                  },
                                ));
                          })),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                          margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                          decoration: BoxDecoration(
                              color: PaletteColors.blue2,
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            Icon(
                              Icons.currency_rupee,
                              size: 25,
                              color: netReturnsForDynStocks >= 0
                                  ? AccentColors.green2
                                  : AccentColors.red2,
                            ),
                            Text(
                              netReturnsForDynStocks.toStringAsFixed(2),
                              style: GoogleFonts.lusitana(
                                color: netReturnsForDynStocks >= 0
                                    ? AccentColors.green2
                                    : AccentColors.red2,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Container(
                                margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: Text(
                                  'Net Returns',
                                  style: GoogleFonts.lusitana(
                                    color: PaletteColors.blue4,
                                    fontSize: 15,
                                  ),
                                ))
                          ]))
                    ]),
                    Container(
                        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                                width: screenSize.width * 0.45,
                                height: 70,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: PaletteColors.green2, width: 4),
                                    borderRadius: BorderRadius.circular(25),
                                    gradient: LinearGradient(
                                        colors: [
                                          PaletteColors.blue1,
                                          PaletteColors.blue2,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter)),
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25))),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                          Colors.transparent,
                                        )),
                                    child: Text(
                                      'Edit DynStock',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                      setState(() {
                                        shouldLoadInitialValues = true;
                                      });
                                    })),
                            Container(
                                width: screenSize.width * 0.45,
                                height: 70,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: PaletteColors.green2, width: 4),
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                        colors: [
                                          PaletteColors.blue1,
                                          PaletteColors.blue2,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter)),
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30))),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                          Colors.transparent,
                                        )),
                                    child: Text(
                                      'View transactions',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewTransactionsScreen(
                                                    customStockCode:
                                                        currentDynStockCode,
                                                  )));
                                    })),
                          ],
                        )),
                    Container(
                        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                                width: screenSize.width * 0.45,
                                height: 70,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: PaletteColors.green2, width: 4),
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                        colors: [
                                          PaletteColors.blue1,
                                          PaletteColors.blue2,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter)),
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25))),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                          Colors.transparent,
                                        )),
                                    child: Text(
                                      'View Chart',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: ((context) =>
                                                  ViewChartForSpecificDynStockScreen(
                                                      currentDynStockCode:
                                                          currentDynStockCode))));
                                    })),
                          ],
                        )),
                    Container(
                        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                                width: screenSize.width * 0.45,
                                height: 70,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AccentColors.red2, width: 4),
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                        colors: [
                                          AccentColors.red1,
                                          AccentColors.yellow1,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter)),
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25))),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                          Colors.transparent,
                                        )),
                                    child: Text(
                                      currentDynStock.lastTransactionType ==
                                              ETransactionType.BUY.name
                                          ? 'Force Sell'
                                          : 'Force Buy',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    onPressed: () {
                                      showForceTransactionDialog(
                                          currentDynStock);
                                    })),
                          ],
                        ))
                  ],
                )));
              } else {
                return Text('Hi');
              }
            }));
  }
}
