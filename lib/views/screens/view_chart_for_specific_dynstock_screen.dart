import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/bar_chart.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/redux/state/dyn_stocks.state.dart';
import 'package:dynstocks/services/gmail_error_message.service.dart';
import 'package:dynstocks/static/post-market-timer.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/screens/view_dynstocks_list_screen.dart';
import 'package:dynstocks/views/screens/view_transactions_screen.dart';
import 'package:dynstocks/views/widgets/bottom_navigation_bar_custom.dart';
import 'package:dynstocks/views/widgets/dyn_stocks_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:fl_chart/fl_chart.dart';
import 'package:wakelock/wakelock.dart';
import 'package:yahoofin/yahoofin.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'dart:math';

class ViewChartForSpecificDynStockScreen extends StatefulWidget {
  String currentDynStockCode;
  ViewChartForSpecificDynStockScreen(
      {Key? key, required this.currentDynStockCode})
      : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _ViewChartForSpecificDynStockScreenState createState() =>
      _ViewChartForSpecificDynStockScreenState(
          currentDynStockCode: currentDynStockCode);
}

class _ViewChartForSpecificDynStockScreenState
    extends State<ViewChartForSpecificDynStockScreen> with RouteAware {
  String currentDynStockCode;
  _ViewChartForSpecificDynStockScreenState({required this.currentDynStockCode});
  DynStock? currentDynStock;
  String currentStockTimePeriod = '1d';
  bool isTimedTickerFetchStarted = false;
  List<String> stockTimePeriod =
      List.from(['1d', '1w', '1m', '3m', '6m', '1y']);

  List<FlSpot> dynStockChartPoints = [];
  double netReturnsForDynStock = 0.0;
  double netCAGR = 0.0;
  bool isLoaded = false;
  bool reload = false;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    isLoaded = false;
  }

  // This function starts the periodic timer for the ticker data action
  // If the ticker timer hasn't started , there is an explicit timer for the screen which runs,
  // till the ticker timer is started
  void startPeriodicTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        PostMarketTimer.startPostMarketTimer(context);
        bool timerStarted = TimedTickerCall.startTimedTickerCallForDynStocks(
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

  String userId = appStore.state.userId;

  Future<void> parseDataForDynStockPriceChart() async {
    double netReturns = 0.0;
    double compoundingPeriod = 365;
    List<FlSpot> chartPoints = appStore.state.allDynStocks.data
        .firstWhere((dynStock) => dynStock.stockCode == currentDynStockCode)
        .transactions
        .mapIndexed((index, transaction) {
      int multiplier = transaction.type == 'SELL' ? 1 : -1;
      DateTime now = DateTime.now();
      now = now.subtract(Duration(
          hours: now.hour,
          minutes: now.minute,
          seconds: now.second,
          milliseconds: now.millisecond,
          microseconds: now.microsecond));
      DateTime transactionTime =
          DateTime.fromMillisecondsSinceEpoch(transaction.transactionTime.date);
      transactionTime = transactionTime.subtract(Duration(
          hours: transactionTime.hour,
          minutes: transactionTime.minute,
          seconds: transactionTime.second,
          milliseconds: transactionTime.millisecond,
          microseconds: transactionTime.microsecond));
      switch (currentStockTimePeriod) {
        case '1d':
          if (now.compareTo(transactionTime.add(Duration(days: 0))) <= 0) {
            netReturns += transaction.amount * multiplier;
            compoundingPeriod = 365;
          }
          break;
        case '1w':
          if (now.compareTo(transactionTime.add(Duration(days: 6))) <= 0) {
            netReturns += transaction.amount * multiplier;
            compoundingPeriod = 52;
          }
          break;
        case '1m':
          if (now.compareTo(transactionTime.add(Duration(days: 30))) <= 0) {
            netReturns += transaction.amount * multiplier;
            compoundingPeriod = 12;
          }
          break;
        case '3m':
          if (now.compareTo(transactionTime.add(Duration(days: 90))) <= 0) {
            netReturns += transaction.amount * multiplier;
            compoundingPeriod = 4;
          }
          break;
        case '6m':
          if (now.compareTo(transactionTime.add(Duration(days: 180))) <= 0) {
            netReturns += transaction.amount * multiplier;
            compoundingPeriod = 2;
          }
          break;
        case '1y':
          if (now.compareTo(transactionTime.add(Duration(days: 365))) <= 0) {
            netReturns += transaction.amount * multiplier;
            compoundingPeriod = 1;
          }
          break;
      }
      return FlSpot(
        transaction.transactionTime.date.toDouble(),
        transaction.stockPrice,
      );
    }).toList();
    DateTime now = DateTime.now();
    double amountInvested = appStore.state.allDynStocks.data
        .firstWhere((dynStock) => dynStock.stockCode == currentDynStockCode)
        .transactions[0]
        .amount;
    double cagr = pow((netReturns / amountInvested) as num,
            (1 / (1 / compoundingPeriod) as num))
        .toDouble();
    cagr = (cagr - 1) * 100;
    now = now.subtract(Duration(
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond));
    switch (currentStockTimePeriod) {
      case '1d':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          timeOfTransaction = timeOfTransaction.subtract(Duration(
              hours: timeOfTransaction.hour,
              minutes: timeOfTransaction.minute,
              seconds: timeOfTransaction.second,
              milliseconds: timeOfTransaction.millisecond,
              microseconds: timeOfTransaction.microsecond));
          return now.subtract(Duration(days: 0)).compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '1w':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          timeOfTransaction = timeOfTransaction.subtract(Duration(
              hours: timeOfTransaction.hour,
              minutes: timeOfTransaction.minute,
              seconds: timeOfTransaction.second,
              milliseconds: timeOfTransaction.millisecond,
              microseconds: timeOfTransaction.microsecond));
          return now.subtract(Duration(days: 6)).compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '1m':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          timeOfTransaction = timeOfTransaction.subtract(Duration(
              hours: timeOfTransaction.hour,
              minutes: timeOfTransaction.minute,
              seconds: timeOfTransaction.second,
              milliseconds: timeOfTransaction.millisecond,
              microseconds: timeOfTransaction.microsecond));
          return now
                  .subtract(Duration(days: 30))
                  .compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '3m':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          timeOfTransaction = timeOfTransaction.subtract(Duration(
              hours: timeOfTransaction.hour,
              minutes: timeOfTransaction.minute,
              seconds: timeOfTransaction.second,
              milliseconds: timeOfTransaction.millisecond,
              microseconds: timeOfTransaction.microsecond));
          return now
                  .subtract(Duration(days: 90))
                  .compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '6m':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          timeOfTransaction = timeOfTransaction.subtract(Duration(
              hours: timeOfTransaction.hour,
              minutes: timeOfTransaction.minute,
              seconds: timeOfTransaction.second,
              milliseconds: timeOfTransaction.millisecond,
              microseconds: timeOfTransaction.microsecond));
          return now
                  .subtract(Duration(days: 180))
                  .compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '1y':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          timeOfTransaction = timeOfTransaction.subtract(Duration(
              hours: timeOfTransaction.hour,
              minutes: timeOfTransaction.minute,
              seconds: timeOfTransaction.second,
              milliseconds: timeOfTransaction.millisecond,
              microseconds: timeOfTransaction.microsecond));
          return now
                  .subtract(Duration(days: 365))
                  .compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
    }
    setState(() {
      dynStockChartPoints = chartPoints;
      netReturnsForDynStock = netReturns;
      netCAGR = cagr;
    });
  }

  @override
  Widget build(BuildContext context) {
    Wakelock.enabled.then((value) {
      if (!value) {
        Wakelock.enable();
        // GmailErrorMessageService.signIntoGoogle();
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
    Size screenSize = MediaQuery.of(context).size;
    if (!isLoaded) {
      parseDataForDynStockPriceChart();
      setState(() {
        isLoaded = true;
      });
    }
    return Scaffold(
      body: StoreConnector<AppState, AppState>(
          converter: ((store) => store.state),
          builder: (context, state) {
            return SingleChildScrollView(
              child: Container(
                  margin: EdgeInsets.fromLTRB(10, 30, 10, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
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
                                  ))),
                          Container(
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: Text(
                                'VIEW CHART',
                                style: GoogleFonts.outfit(
                                  fontSize: 30 /
                                      int.parse((1 +
                                              (currentDynStockCode.length / 10)
                                                  .toInt())
                                          .toString()),
                                  color: PaletteColors.blue2,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                        ],
                      ),
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
                            itemCount: stockTimePeriod.length,
                            itemBuilder: ((context, index) {
                              return Container(
                                  width: 55,
                                  height: 25,
                                  decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular((25))),
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
                                                currentStockTimePeriod ==
                                                        stockTimePeriod[index]
                                                    ? PaletteColors.blue2
                                                    : PaletteColors.blue3)),
                                    child: Text(
                                      stockTimePeriod[index],
                                      style: GoogleFonts.lusitana(
                                        color: currentStockTimePeriod ==
                                                stockTimePeriod[index]
                                            ? Colors.white
                                            : PaletteColors.blue2,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        currentStockTimePeriod =
                                            stockTimePeriod[index];
                                        isLoaded = false;
                                      });
                                    },
                                  ));
                            })),
                      ),
                      Container(
                        width: screenSize.width,
                        height: screenSize.height * 0.5,
                        margin: EdgeInsets.fromLTRB(0, 20, 0, 10),
                        padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                              PaletteColors.blue2,
                              Colors.black,
                            ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter)),
                        child: LineChart(LineChartData(
                            lineTouchData: LineTouchData(
                                enabled: true,
                                handleBuiltInTouches: true,
                                touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: ((touchedSpots) {
                                      return touchedSpots.map((touchedSpot) {
                                        DateTime transactionTime =
                                            DateTime.fromMillisecondsSinceEpoch(
                                                touchedSpot.x.round());
                                        return LineTooltipItem(
                                            '${touchedSpot.y}\n',
                                            GoogleFonts.daysOne(
                                              color: AccentColors.blue1,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                                  style: GoogleFonts.daysOne(
                                                    color: AccentColors.yellow1,
                                                    fontSize: 10,
                                                  ),
                                                  text:
                                                      '${transactionTime.hour}:${transactionTime.minute}:${transactionTime.second} ${transactionTime.day}/${transactionTime.month}/${transactionTime.year}')
                                            ]);
                                      }).toList();
                                    }),
                                    tooltipBgColor: Colors.white)),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  top: BorderSide(color: Colors.transparent),
                                  bottom: BorderSide(color: Colors.transparent),
                                  left: BorderSide(color: Colors.transparent),
                                  right: BorderSide(color: Colors.transparent),
                                )),
                            lineBarsData: [
                              LineChartBarData(
                                  dotData: FlDotData(show: true),
                                  spots: dynStockChartPoints,
                                  isCurved: false,
                                  barWidth: 5,
                                  color: Colors.blue),
                            ],
                            titlesData: FlTitlesData(
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 50,
                                        getTitlesWidget: (value, meta) {
                                          return Container(
                                              child: Text(
                                                  value.toStringAsFixed(2),
                                                  style: GoogleFonts.lusitana(
                                                      fontSize: 15,
                                                      color: Colors.white)));
                                        })),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    DateTime time =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            value.toInt());
                                    String timeString = '';
                                    switch (currentStockTimePeriod) {
                                      case '1d':
                                        timeString =
                                            '${time.hour}:${time.minute}';
                                        break;
                                      case '1w':
                                        timeString =
                                            '${time.month}-${time.day}';
                                        break;
                                      case '1m':
                                        timeString =
                                            '${time.month}-${time.day}';
                                        break;
                                      case '3m':
                                        timeString =
                                            '${time.month}-${time.day}';
                                        break;
                                      case '6m':
                                        timeString =
                                            '${time.month}-${time.day}';
                                        break;
                                      case '1y':
                                        timeString =
                                            '${time.month} ${time.day}';
                                        break;
                                    }
                                    return Container(
                                        child: Text(
                                      timeString,
                                      style: GoogleFonts.lusitana(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ));
                                  },
                                ))))),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              child: Container(
                                  height: screenSize.height * 0.1,
                                  padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  decoration: BoxDecoration(
                                      color: PaletteColors.blue3,
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        netReturnsForDynStock
                                            .toStringAsFixed(2),
                                        style: GoogleFonts.daysOne(
                                          color: PaletteColors.blue2,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Net Returns',
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
                                  height: screenSize.height * 0.1,
                                  padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  decoration: BoxDecoration(
                                      color: PaletteColors.blue3,
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        netCAGR.toStringAsFixed(2),
                                        style: GoogleFonts.daysOne(
                                          color: PaletteColors.blue2,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'CAGR',
                                        style: GoogleFonts.outfit(
                                          color: PaletteColors.blue4,
                                          fontSize: 15,
                                        ),
                                      )
                                    ],
                                  )),
                            )
                          ]),
                    ],
                  )),
            );
          }),
    );
  }
}
