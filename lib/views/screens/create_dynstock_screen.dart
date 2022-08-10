import 'dart:async';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/bar_chart.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/ticker_data.service.dart';
import 'package:dynstocks/services/transactions.service.dart';
import 'package:dynstocks/static/toast_message_handler.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/screens/view_dynstocks_list_screen.dart';
import 'package:dynstocks/views/widgets/bottom_navigation_bar_custom.dart';
import 'package:dynstocks/views/widgets/transactions_today_bar_chart.dart';
import 'package:dynstocks/views/widgets/transactions_today_details.dart';
import 'package:dynstocks/views/screens/view_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yahoofin/yahoofin.dart';
import '../../models/transactions.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../../models/colors.dart';
import 'package:dynstocks/models/yahoo_finance_data.dart';

class CreateDynStockScreen extends StatefulWidget {
  const CreateDynStockScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _CreateDynStockScreenState createState() => _CreateDynStockScreenState();
}

class _CreateDynStockScreenState extends State<CreateDynStockScreen>
    with RouteAware {
  String userId = appStore.state.userId;
  bool isTimedTickerFetchStarted = false;
  bool doesDynStockAlreadyExist = false;
  String stockSearchInput = '';
  double? searchedStockPrice;
  double? searchedStockPriceChange;
  double? searchedStockPriceChangePercent;

  EDSTPUnit currentDSTPUnit = EDSTPUnit.Price;
  Map<EDSTPUnit, String> DSTPUnitMap = Map();
  String currentKOTAKStockCode = '';
  String currentInstrumentToken = '';
  String currentStockName = '';
  EExchange currentExchange = EExchange.NSE;
  EStockType currentStockType = EStockType.EQ;
  String currentNoOfStocks = '0';
  String currentBTP = '0.0';
  String currentSTP = '0.0';
  bool creatingDynStock = false;
  bool errorMessageShown = false;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    super.initState();
    DSTPUnitMap[EDSTPUnit.Price] = 'Price';
    DSTPUnitMap[EDSTPUnit.Percentage] = 'Percentage';
  }

  @override
  void didPop() {
    stopPeriodicTimer();
    super.didPop();
  }

  @override
  void didPush() {
    super.didPush();
    startPeriodicTimer();
  }

  @override
  void didPushNext() {
    stopPeriodicTimer();
    super.didPushNext();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    startPeriodicTimer();
  }

  @override
  void dispose() {
    stopPeriodicTimer();
    super.dispose();
  }

  // This function starts the periodic timer for the ticker data action
  // If the ticker timer hasn't started , there is an explicit timer for the screen which runs,
  // till the ticker timer is started
  void startPeriodicTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
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

  // This function is invoked when the user searches for a particular ticker
  // yFin package is used for the purpose, to get price and priceChange
  void querySearchedTickerPrice() async {
    StockInfo info = yFin.getStockInfo(ticker: stockSearchInput);
    StockQuote price = await yFin.getPrice(stockInfo: info);
    StockQuote priceChange = await yFin.getPriceChange(stockInfo: info);
    if (mounted) {
      setState(() {
        searchedStockPrice = price.currentPrice;
        searchedStockPriceChange = priceChange.regularMarketChange;
        searchedStockPriceChangePercent =
            priceChange.regularMarketChangePercent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    if (appStore.state.allDynStocks.createFailed && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                'Error while creating DynStock'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    if (mounted) {
      if (appStore.state.allDynStocks.creating &&
          !appStore.state.allDynStocks.created) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
              ToastMessageHandler.showInfoMessageSnackBar(
                  'Creating DynStock.....'));
        });
        setState(() {
          creatingDynStock = true;
        });
      } else if (!appStore.state.allDynStocks.creating &&
          appStore.state.allDynStocks.created &&
          creatingDynStock) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
              ToastMessageHandler.showSuccessMessageSnackBar(
                  'DynStock Created'));
          Future.delayed(Duration(seconds: 2), () {
            Route newRoute = MaterialPageRoute(
                builder: (context) => ViewDynStocksListScreen());
            Navigator.pushReplacement(context, newRoute);
          });
        });
        setState(() {
          stockSearchInput = '';
          creatingDynStock = false;
        });
      } else if (appStore.state.allDynStocks.createFailed && creatingDynStock) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
              ToastMessageHandler.showErrorMessageSnackBar(
                  '${appStore.state.allDynStocks.error.toString()}'));
        });
        setState(() {
          creatingDynStock = false;
        });
      }
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: StoreConnector<AppState, AppState>(
          onDidChange: (previousState, state) {
            if (state.allDynStocks.createFailed && !errorMessageShown) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    ToastMessageHandler.showErrorMessageSnackBar(
                        'Error while creating DynStock'));
              });
              setState(() {
                errorMessageShown = true;
              });
            }
          },
          converter: ((store) => store.state),
          builder: (context, state) => Container(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create DynStock',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 35,
                                    color: PaletteColors.blue2),
                              )
                            ]),
                      ),
                      Container(
                          width: screenSize.width * 0.85,
                          height: 60,
                          margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                          decoration: BoxDecoration(
                              color: PaletteColors.blue3,
                              borderRadius: BorderRadius.circular(25)),
                          child: TextFormField(
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                                hintText: 'Enter Yahoo stock code',
                                icon: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                )),
                            style: GoogleFonts.lusitana(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: PaletteColors.purple1),
                            initialValue: stockSearchInput,
                            onChanged: (newValue) async {
                              setState(() {
                                stockSearchInput = newValue;
                              });
                            },
                            onEditingComplete: () async {
                              bool flag = false;
                              state.allDynStocks.data.every((element) {
                                if (element.yFinStockCode == stockSearchInput) {
                                  flag = true;
                                  return false;
                                }
                                return true;
                              });
                              if (!flag) {
                                DateTime now = DateTime.now();
                                if (now.hour < 9 ||
                                    now.hour > 16 ||
                                    now.weekday > 5) {
                                  TimedTickerCall.timerForCustomStock?.cancel();
                                  querySearchedTickerPrice();
                                } else {
                                  TimedTickerCall.timerForCustomStock?.cancel();
                                  TimedTickerCall.timerForCustomStock =
                                      Timer.periodic(Duration(seconds: 1),
                                          (timer) {
                                    querySearchedTickerPrice();
                                    DateTime now1 = DateTime.now();
                                    if (now1.hour < 9 ||
                                        now1.hour > 16 ||
                                        now.weekday > 5) {
                                      TimedTickerCall.timerForCustomStock
                                          ?.cancel();
                                      querySearchedTickerPrice();
                                    }
                                  });
                                }
                              }
                              setState(() {
                                doesDynStockAlreadyExist = flag;
                                currentKOTAKStockCode = '';
                                currentInstrumentToken = '';
                                currentStockName = '';
                                currentNoOfStocks = '';
                                currentDSTPUnit = EDSTPUnit.Price;
                                currentExchange = EExchange.NSE;
                                currentStockType = EStockType.EQ;
                                currentBTP = '';
                                currentSTP = '';
                              });
                            },
                          )),
                      if (doesDynStockAlreadyExist)
                        (Container(
                          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'DynStock already exists for the code',
                                  style: GoogleFonts.lusitana(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AccentColors.red1),
                                ),
                              ]),
                        )),
                      if (searchedStockPrice != null &&
                          !doesDynStockAlreadyExist)
                        (Container(
                            margin: EdgeInsets.fromLTRB(0, 15, 0, 0),
                            padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
                            width: screenSize.width * 0.85,
                            decoration: BoxDecoration(
                                color: PaletteColors.blue3,
                                borderRadius: BorderRadius.circular(30)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                    child: Column(
                                  children: [
                                    Row(children: [
                                      Icon(
                                        Icons.currency_rupee,
                                        size: 35,
                                        color: searchedStockPriceChange! >= 0
                                            ? (AccentColors.green1)
                                            : AccentColors.red1,
                                      ),
                                      Text(
                                        searchedStockPrice!.toStringAsFixed(2),
                                        style: GoogleFonts.overlock(
                                            fontSize: 35,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                searchedStockPriceChange! >= 0
                                                    ? (AccentColors.green1)
                                                    : AccentColors.red1),
                                      ),
                                    ]),
                                    Text(
                                      'Stock Price',
                                      style: GoogleFonts.overlock(
                                          fontSize: 22,
                                          color: PaletteColors.blue4),
                                    ),
                                  ],
                                )),
                                Column(children: [
                                  Container(
                                    child: Text(
                                      (searchedStockPrice! > 0 ? '+' : '') +
                                          searchedStockPriceChange!
                                              .toStringAsFixed(2),
                                      style: GoogleFonts.overlock(
                                          fontSize: 20,
                                          color: searchedStockPriceChange! >= 0
                                              ? (AccentColors.green1)
                                              : AccentColors.red1),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      '(' +
                                          (searchedStockPrice! > 0 ? '+' : '') +
                                          searchedStockPriceChangePercent!
                                              .toStringAsFixed(2) +
                                          '% )',
                                      style: GoogleFonts.overlock(
                                          fontSize: 20,
                                          color: searchedStockPriceChange! >= 0
                                              ? (AccentColors.green1)
                                              : AccentColors.red1),
                                    ),
                                  )
                                ])
                              ],
                            ))),
                      if (searchedStockPrice != null &&
                          !doesDynStockAlreadyExist)
                        (Container(
                          margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                          padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                  topRight: Radius.circular(40),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20)),
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    PaletteColors.blue1,
                                    PaletteColors.blue2
                                  ])),
                          child: Container(
                              height: screenSize.height * 0.375,
                              child: ListView(children: [
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'KOTAK Stock Code',
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
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please enter a value';
                                              }
                                              return null;
                                            },
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            initialValue: currentKOTAKStockCode,
                                            keyboardType: TextInputType.text,
                                            onChanged: (newValue) =>
                                                setState(() {
                                              currentKOTAKStockCode = newValue;
                                            }),
                                          ))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'Instrument Token',
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
                                            initialValue:
                                                currentInstrumentToken,
                                            keyboardType: TextInputType.number,
                                            onChanged: (newValue) =>
                                                setState(() {
                                              currentInstrumentToken = newValue;
                                            }),
                                          ))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'Stock Name',
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
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Please enter a value';
                                              }
                                              return null;
                                            },
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            initialValue: currentStockName,
                                            keyboardType: TextInputType.text,
                                            onChanged: (newValue) =>
                                                setState(() {
                                              currentStockName = newValue;
                                            }),
                                          ))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(20, 5, 10, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'Exchange',
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
                                              value: currentExchange.name,
                                              items: EExchange.values.map((e) {
                                                return DropdownMenuItem<String>(
                                                    value: e.name.toString(),
                                                    child: Text(
                                                      e.name.toString(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ));
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  currentExchange = EExchange
                                                      .values
                                                      .firstWhere((element) =>
                                                          element.name ==
                                                          newValue);
                                                });
                                              })),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(20, 5, 10, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: Column(children: [
                                      Row(children: [
                                        Text(
                                          'Stock Type',
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
                                              value: currentStockType.name,
                                              items: EStockType.values.map((e) {
                                                return DropdownMenuItem<String>(
                                                    value: e.name.toString(),
                                                    child: Text(
                                                      e.name.toString(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ));
                                              }).toList(),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  currentStockType = EStockType
                                                      .values
                                                      .firstWhere((element) =>
                                                          element.name ==
                                                          newValue);
                                                });
                                              })),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(20, 5, 10, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
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
                                                if (currentDSTPUnit
                                                        .toString()
                                                        .split('.')[1] !=
                                                    newValue) {
                                                  setState(() {
                                                    currentBTP = '';
                                                    currentSTP = '';
                                                  });
                                                }
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
                                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
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
                                            initialValue: currentNoOfStocks,
                                            keyboardType: TextInputType.number,
                                            onChanged: (newValue) =>
                                                setState(() {
                                              currentNoOfStocks = newValue;
                                            }),
                                          ))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
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
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              initialValue: currentBTP,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (newValue) =>
                                                  setState(() {
                                                    currentBTP = newValue;
                                                  })))),
                                    ])),
                                Container(
                                    margin: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(30)),
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
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              initialValue: currentSTP,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (newValue) =>
                                                  setState(() {
                                                    currentSTP = newValue;
                                                  })))),
                                    ])),
                              ])),
                        )),
                      if (searchedStockPrice != null &&
                          !doesDynStockAlreadyExist)
                        (Container(
                          margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                                    PaletteColors.blue1,
                                    PaletteColors.blue2,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: PaletteColors.green2, width: 4)),
                          child: ElevatedButton(
                            style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                    EdgeInsets.fromLTRB(25, 15, 25, 15)),
                                shape:
                                    MaterialStateProperty.all<OutlinedBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25))),
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.transparent)),
                            child: Text(
                              'Create',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            onPressed: () {
                              StoreProvider.of<AppState>(context).dispatch(
                                CreateDynStockAction(
                                    userId: state.userId,
                                    price: searchedStockPrice as double,
                                    body: DynStockBody(
                                      stockCode: currentKOTAKStockCode,
                                      instrumentToken: currentInstrumentToken,
                                      yFinStockCode: stockSearchInput,
                                      stockName: currentStockName,
                                      exchange: currentExchange.name,
                                      stockType: currentStockType.name,
                                      noOfStocks: int.parse(currentNoOfStocks),
                                      DSTPUnit:
                                          currentDSTPUnit == EDSTPUnit.Price
                                              ? 'Price'
                                              : 'Percentage',
                                      BTPr: currentDSTPUnit == EDSTPUnit.Price
                                          ? double.parse(currentBTP)
                                          : 0.0,
                                      BTPe: currentDSTPUnit ==
                                              EDSTPUnit.Percentage
                                          ? double.parse(currentBTP)
                                          : 0.0,
                                      STPr: currentDSTPUnit == EDSTPUnit.Price
                                          ? double.parse(currentSTP)
                                          : 0.0,
                                      STPe: currentDSTPUnit ==
                                              EDSTPUnit.Percentage
                                          ? double.parse(currentSTP)
                                          : 0.0,
                                    )),
                              );
                              setState(() {
                                errorMessageShown = false;
                              });
                            },
                          ),
                        ))
                    ]),
              )),
      bottomNavigationBar: BottomNavigationBarCustom(
        screenSize: screenSize,
        selectedIndex: 2,
      ),
    );
  }
}
