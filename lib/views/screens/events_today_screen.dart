import 'dart:async';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/bar_chart.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/actions/local_user_creds.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/transactions.service.dart';
import 'package:dynstocks/static/post-market-timer.dart';
import 'package:dynstocks/static/toast_message_handler.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/widgets/bottom_navigation_bar_custom.dart';
import 'package:dynstocks/views/widgets/transactions_today_bar_chart.dart';
import 'package:dynstocks/views/widgets/transactions_today_details.dart';
import 'package:dynstocks/views/screens/view_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import '../../models/transactions.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../../models/colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EventsTodayScreen extends StatefulWidget {
  const EventsTodayScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _EventsTodayScreenState createState() => _EventsTodayScreenState();
}

class _EventsTodayScreenState extends State<EventsTodayScreen> with RouteAware {
  List<Transaction>? transactionsToday;
  List<ITransactionsBarChart> barChartData =
      List<ITransactionsBarChart>.empty(growable: true);
  List<charts.Series<ITransactionsBarChart, String>> barChartsRenderData = [];
  double maxTradedAmount = 0.0;
  Map<String, int> noOfStocks = Map();
  double netReturnsToday = 0.0;
  bool isLoaded = false;
  int selectedBottomBarIndex = 0;
  bool isTimedTickerFetchStarted = false;
  bool errorMessageShown = false;
  bool reload = false;
  bool timerCreatedFor915 = false;
  int timedTickerPeriod = 1;
  void resetState() {
    transactionsToday = null;
    isLoaded = false;
    barChartData = List<ITransactionsBarChart>.empty(growable: true);
    noOfStocks.putIfAbsent('SELL', () => 0);
    noOfStocks.putIfAbsent('BUY', () => 0);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    super.initState();
    if (appStore.state.userId.isEmpty) {
      SharedPreferences.getInstance().then((prefs) {
        String userId = prefs.getString('userId') as String;
        DateTime now = DateTime.now();
        String accessCode =
            prefs.getString('accessCode ${now.day}/${now.month}/${now.year}')
                as String;
        String jwtToken = prefs.getString('KOTAK jwtToken') as String;

        StoreProvider.of<AppState>(context)
            .dispatch(SetUserIdAction(userId: userId));
        StoreProvider.of<AppState>(context)
            .dispatch(SetAccessCodeAction(accessCode: accessCode));
        StoreProvider.of<AppState>(context).dispatch(
            KotakStockAPILoginSuccessAction(
                data: KotakStockApiLoginResponse(
                    message: 'Login Successful', token: jwtToken)));
      });
    }
    transactionsToday = null;
    isLoaded = false;
    noOfStocks.putIfAbsent('SELL', () => 0);
    noOfStocks.putIfAbsent('BUY', () => 0);
  }

  void getTransactionsForToday() async {
    try {
      if (appStore.state.userId.isNotEmpty &&
          appStore.state.accessCode.isNotEmpty) {
        DateTime now = DateTime.now();
        String formattedDate = DateFormat('MMM dd yyyy').format(now);
        TransactionsResponse temp = await TransactionsService()
            .getTransactionsForDate(appStore.state.userId, date: formattedDate);
        List<Transaction> res = temp.items;
        List<ITransactionsBarChart> barChartData = [
          ITransactionsBarChart(
            id: 1,
            time: '09:00',
            percentage: 0.0,
            amount: 0.0,
            color: charts.ColorUtil.fromDartColor(Colors.black),
            labelColor: charts.ColorUtil.fromDartColor(Colors.black),
          ),
          ITransactionsBarChart(
            id: 2,
            time: '10:00',
            percentage: 0.0,
            amount: 0.0,
            color: charts.ColorUtil.fromDartColor(Colors.black),
            labelColor: charts.ColorUtil.fromDartColor(Colors.black),
          ),
          ITransactionsBarChart(
            id: 3,
            time: '11:00',
            percentage: 0.0,
            amount: 0.0,
            color: charts.ColorUtil.fromDartColor(Colors.black),
            labelColor: charts.ColorUtil.fromDartColor(Colors.black),
          ),
          ITransactionsBarChart(
            id: 4,
            time: '12:00',
            percentage: 0.0,
            amount: 0.0,
            color: charts.ColorUtil.fromDartColor(Colors.black),
            labelColor: charts.ColorUtil.fromDartColor(Colors.black),
          ),
          ITransactionsBarChart(
            id: 5,
            time: '01:00',
            percentage: 0.0,
            amount: 0.0,
            color: charts.ColorUtil.fromDartColor(Colors.black),
            labelColor: charts.ColorUtil.fromDartColor(Colors.black),
          ),
          ITransactionsBarChart(
            id: 6,
            time: '02:00',
            percentage: 0.0,
            amount: 0.0,
            color: charts.ColorUtil.fromDartColor(Colors.black),
            labelColor: charts.ColorUtil.fromDartColor(Colors.black),
          ),
          ITransactionsBarChart(
            id: 7,
            time: '03:00',
            percentage: 0.0,
            amount: 0.0,
            color: charts.ColorUtil.fromDartColor(Colors.black),
            labelColor: charts.ColorUtil.fromDartColor(Colors.black),
          ),
        ];
        noOfStocks['SELL'] = 0;
        noOfStocks['BUY'] = 0;
        res.forEach((transaction) {
          DateTime transactionTimeUTC = DateTime.fromMicrosecondsSinceEpoch(
              transaction.transactionTime.date * 1000,
              isUtc: true);
          DateTime transactionTimeIST =
              transactionTimeUTC.add(const Duration(seconds: 19800));
          String time = '${transactionTimeIST.hour}:00';
          double multiplier = 1.0;
          if (transaction.type == 'BUY') {
            multiplier = -1.0;
            noOfStocks.update('BUY', (value) => value + transaction.noOfStocks);
          } else {
            noOfStocks.update(
                'SELL', (value) => value + transaction.noOfStocks);
          }
          if (time.contains('9:00')) {
            barChartData[0].amount += (transaction.amount * multiplier);
          } else if (time.contains('10:00')) {
            barChartData[1].amount += (transaction.amount * multiplier);
          } else if (time.contains('11:00')) {
            barChartData[2].amount += (transaction.amount * multiplier);
          } else if (time.contains('12:00')) {
            barChartData[3].amount += (transaction.amount * multiplier);
          } else if (time.contains('13:00')) {
            barChartData[4].amount += (transaction.amount * multiplier);
          } else if (time.contains('14:00')) {
            barChartData[5].amount += (transaction.amount * multiplier);
          } else if (time.contains('15:00')) {
            barChartData[6].amount += (transaction.amount * multiplier);
          }
        });

        double maxAmount = 0.0;
        barChartData.forEach((element) {
          element.amount = double.parse(element.amount.toStringAsFixed(2));
          netReturnsToday += element.amount;
          if ((element.amount.abs()) > maxAmount) {
            maxAmount = element.amount.abs();
          }
        });
        netReturnsToday = double.parse(netReturnsToday.toStringAsFixed(2));

        if (maxAmount > 0) {
          barChartData.forEach((element) {
            double percentage = element.amount * 100 / maxAmount;
            Color color = (Colors.black);
            Color labelColor = Colors.black;
            if (percentage >= 50 && percentage <= 100) {
              color = (AccentColors.green2);
              labelColor = (AccentColors.green1);
            } else if (percentage >= 0 && percentage < 50) {
              color = (AccentColors.yellow2);
              labelColor = (AccentColors.yellow1);
            } else if (percentage >= -50 && percentage < 0) {
              color = (AccentColors.blue2);
              labelColor = (AccentColors.blue1);
            } else if (percentage >= -100 && percentage < -50) {
              color = (AccentColors.red2);
              labelColor = (AccentColors.red1);
            }

            element.percentage = percentage;
            element.color = charts.ColorUtil.fromDartColor(color);
            element.labelColor = charts.ColorUtil.fromDartColor(labelColor);
          });
        }

        barChartsRenderData = [
          charts.Series(
            id: "BarChart",
            data: barChartData,
            measureFn: (ITransactionsBarChart barChart, _) =>
                barChart.percentage,
            domainFn: (ITransactionsBarChart barChart, _) => (barChart.time),
            colorFn: (ITransactionsBarChart barChart, _) => barChart.color,
            labelAccessorFn: (ITransactionsBarChart barChart, _) =>
                barChart.percentage.toStringAsFixed(1),
            outsideLabelStyleAccessorFn: (ITransactionsBarChart barChart, _) {
              return charts.TextStyleSpec(
                color: barChart.labelColor,
                fontSize: 10,
                fontWeight: '500',
              );
            },
          ),
        ];
        maxTradedAmount = maxAmount;
        setState(() {
          isLoaded = true;
          transactionsToday = res;
          barChartData = barChartData;
          maxTradedAmount = maxAmount;
        });
      }
    } catch (error) {
      if (!errorMessageShown && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
              ToastMessageHandler.showErrorMessageSnackBar(
                  'Error while fetching today\'s transactions'));
        });
      }
      setState(() {
        errorMessageShown = true;
      });
    }
  }

  @override
  void didPop() {
    stopPeriodicTimer();
    super.didPop();
  }

  @override
  void didPush() {
    super.didPush();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          timedTickerPeriod = prefs.getInt('timedTickerPeriod') as int;
        });
      }
    });
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
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          timedTickerPeriod = prefs.getInt('timedTickerPeriod') as int;
        });
      }
    });
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
  Widget build(BuildContext context) {
    Wakelock.enabled.then((value) {
      if (!value) {
        Wakelock.enable();
      }
    });
    DateTime now = DateTime.now();
    if (((now.hour < 9) || (now.hour == 9 && now.hour < 15)) &&
        !timerCreatedFor915) {
      setState(() {
        timerCreatedFor915 = true;
      });
      Timer.periodic(Duration(seconds: 1), (timer) {
        DateTime currentTime = DateTime.now();
        if (currentTime.hour == 9 && now.hour >= 15) {
          timer.cancel();
          setState(() {
            isLoaded = false;
            reload = true;
          });
          Route newRoute =
              MaterialPageRoute(builder: (context) => EventsTodayScreen());
          Navigator.pushReplacement(context, newRoute);
        }
      });
    }
    if (isLoaded == false &&
        appStore.state.userId.isNotEmpty &&
        appStore.state.accessCode.isNotEmpty) {
      getTransactionsForToday();
    }
    if (!appStore.state.allDynStocks.loaded &&
        !appStore.state.allDynStocks.loading &&
        appStore.state.userId.isNotEmpty &&
        appStore.state.accessCode.isNotEmpty) {
      StoreProvider.of<AppState>(context)
          .dispatch(GetAllDynStocksAction(userId: appStore.state.userId));
      setState(() {
        errorMessageShown = false;
      });
    }
    if (appStore.state.allDynStocks.loadFailed &&
        !errorMessageShown &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.allDynStocks.error}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    if ((appStore.state.transactionsCreateState.error != null) &&
        !errorMessageShown &&
        mounted) {
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
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: Key("EventsTodayScreen"),
      body: StoreConnector<AppState, AppState>(
        onDidChange: (previousState, state) {
          if (appStore.state.allDynStocks.loadFailed &&
              !errorMessageShown &&
              mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                  ToastMessageHandler.showErrorMessageSnackBar(
                      '${state.allDynStocks.error}'));
            });
            setState(() {
              errorMessageShown = true;
            });
          }
          if ((state.transactionsCreateState.error != null) &&
              !errorMessageShown &&
              mounted) {
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
        },
        converter: ((store) => store.state),
        builder: (context, state) => SingleChildScrollView(
            child: Container(
                color: Colors.transparent,
                height: screenSize.height,
                width: screenSize.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                        key: Key("Today's Events"),
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 60, 0, 0),
                          child: Text(
                            'Today\'s Events',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.outfit(
                                color: PaletteColors.blue2,
                                fontSize: 45,
                                fontWeight: FontWeight.bold),
                          ),
                        )),
                    Flexible(
                        key: Key("TransactionsTodayBarChart"),
                        flex: 5,
                        child: TransactionsTodayBarChart(
                            transactionsToday: transactionsToday,
                            barChartsRenderData: barChartsRenderData,
                            screenSize: screenSize)),
                    Flexible(
                        key: Key("TransactionTodayDetails"),
                        flex: 6,
                        child: Container(
                            width: screenSize.width,
                            height: screenSize.height,
                            decoration: BoxDecoration(
                                color: PaletteColors.blue2,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                  topRight: Radius.circular(40),
                                )),
                            child: Column(children: [
                              Flexible(
                                  flex: 4,
                                  child: (TransactionsTodayDetails(
                                    maxTradedAmount: maxTradedAmount,
                                    noOfStocks: noOfStocks,
                                    netReturnsToday: netReturnsToday,
                                    screenSize: screenSize,
                                  ))),
                              Flexible(
                                  flex: 2,
                                  child: Container(
                                      margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                      child: ElevatedButton(
                                          child: Text(
                                            'View all Transactions',
                                            style: GoogleFonts.lusitana(
                                              color: PaletteColors.blue2,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        ViewTransactionsScreen(
                                                          customStockCode: '',
                                                        )));
                                          },
                                          style: ButtonStyle(
                                              shape: MaterialStateProperty.all(
                                                  RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(30)),
                                              )),
                                              fixedSize:
                                                  MaterialStateProperty.all(
                                                      Size(
                                                          screenSize.width *
                                                              0.7,
                                                          screenSize.height *
                                                              0.06)),
                                              backgroundColor:
                                                  MaterialStateProperty
                                                      .resolveWith((states) {
                                                Color finalColor;
                                                states.contains(
                                                        MaterialState.pressed)
                                                    ? finalColor =
                                                        PaletteColors.blue4
                                                    : finalColor =
                                                        PaletteColors.blue3;
                                                return finalColor;
                                              }))))),
                            ]))),
                  ],
                ))),
      ),
      bottomNavigationBar: BottomNavigationBarCustom(
        screenSize: screenSize,
        selectedIndex: 0,
      ),
    );
  }
}
