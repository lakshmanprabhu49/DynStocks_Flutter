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

  List<FlSpot> actualStockChartPoints = [];
  List<FlSpot> dynStockChartPoints = [];
  double netReturnsForDynStock = 0.0;
  bool isLoaded = false;
  List<LineChartBarData> lineChartsBarData = [];
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

  Future<void> parseDataForActualStockPriceChart() async {
    String yFinStockCode =
        appStore.state.allDynStocks.data.firstWhere((element) {
      return element.stockCode == currentDynStockCode;
    }).yFinStockCode;
    StockHistory hist = yFin.initStockHistory(ticker: yFinStockCode);
    StockRange period = StockRange.oneDay;
    StockInterval interval = StockInterval.thirtyMinute;
    switch (currentStockTimePeriod) {
      case '1d':
        period = StockRange.oneDay;
        interval = StockInterval.thirtyMinute;
        break;
      case '1w':
        period = StockRange.fiveDay;
        interval = StockInterval.thirtyMinute;
        break;
      case '1m':
        period = StockRange.oneMonth;
        interval = StockInterval.thirtyMinute;
        break;
      case '3m':
        period = StockRange.threeMonth;
        interval = StockInterval.sixtyMinute;
        break;
      case '6m':
        period = StockRange.sixMonth;
        interval = StockInterval.sixtyMinute;
        break;
      case '1y':
        period = StockRange.oneYear;
        interval = StockInterval.oneDay;
        break;
    }
    StockChart quotes = await yFin.getChartQuotes(
        stockHistory: hist, interval: interval, period: period);
    if (quotes.chartQuotes != null) {
      setState(() {
        actualStockChartPoints = quotes.chartQuotes!.timestamp!.mapIndexed(
          (index, element) {
            return FlSpot(element.toDouble(),
                quotes.chartQuotes!.high![index].toDouble());
          },
        ).toList();
      });
    }
  }

  Future<void> parseDataForDynStockPriceChart() async {
    double netReturns = 0.0;

    List<FlSpot> chartPoints = appStore.state.allDynStocks.data
        .firstWhere((dynStock) => dynStock.stockCode == currentDynStockCode)
        .transactions
        .mapIndexed((index, transaction) {
      int multiplier = transaction.type == 'SELL' ? 1 : -1;
      print(transaction.amount);
      netReturns += transaction.amount * multiplier;
      return FlSpot(
        transaction.transactionTime.date.toDouble(),
        transaction.stockPrice,
      );
    }).toList();
    DateTime now = DateTime.now();
    switch (currentStockTimePeriod) {
      case '1d':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          return now.subtract(Duration(days: 1)).compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '1w':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          return now.subtract(Duration(days: 7)).compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '1m':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          return now
                  .subtract(Duration(days: 31))
                  .compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '3m':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          return now
                  .subtract(Duration(days: 93))
                  .compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '6m':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
          return now
                  .subtract(Duration(days: 186))
                  .compareTo(timeOfTransaction) <=
              0;
        }).toList();
        break;
      case '1y':
        chartPoints = chartPoints.whereIndexed((index, element) {
          DateTime timeOfTransaction =
              DateTime.fromMillisecondsSinceEpoch(element.x.toInt());
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
    });
  }

  Future<void> createLineChartBarData() async {
    String yFinStockCode =
        appStore.state.allDynStocks.data.firstWhere((element) {
      return element.stockCode == currentDynStockCode;
    }).yFinStockCode;
    double netReturns = 0.0;

    // We get all the stock chart data for the stock from yFin API
    StockHistory hist = yFin.initStockHistory(ticker: yFinStockCode);
    StockRange period = StockRange.oneDay;
    StockInterval interval = StockInterval.thirtyMinute;
    switch (currentStockTimePeriod) {
      case '1d':
        period = StockRange.oneDay;
        interval = StockInterval.thirtyMinute;
        break;
      case '1w':
        period = StockRange.fiveDay;
        interval = StockInterval.thirtyMinute;
        break;
      case '1m':
        period = StockRange.oneMonth;
        interval = StockInterval.thirtyMinute;
        break;
      case '3m':
        period = StockRange.threeMonth;
        interval = StockInterval.sixtyMinute;
        break;
      case '6m':
        period = StockRange.sixMonth;
        interval = StockInterval.sixtyMinute;
        break;
      case '1y':
        period = StockRange.oneYear;
        interval = StockInterval.oneDay;
        break;
    }
    StockChart quotes = await yFin.getChartQuotes(
        stockHistory: hist, interval: interval, period: period);
    if (quotes.chartQuotes != null) {
      List<num> stockPricesTimeStamp =
          quotes.chartQuotes!.timestamp as List<num>;
      List<num> stockPrices = quotes.chartQuotes!.close as List<num>;
      // Once data is obtained , we then remove all the points from the line graph which are unnecessary
      List<LineChartBarData> lineCharts = [];
      List<Transaction> transactionsForDynStock = appStore
          .state.allDynStocks.data
          .firstWhere((dynStock) => dynStock.stockCode == currentDynStockCode)
          .transactions;

      Transaction? firstBuyTransaction = transactionsForDynStock
          .firstWhere((transaction) => transaction.type == 'BUY');
      if (firstBuyTransaction != null) {
        int firstBuyTransactionIndex = transactionsForDynStock.indexWhere(
            (element) =>
                element.transactionId.uuid ==
                firstBuyTransaction.dynStockId.uuid);
        int totalTransactionsLength = transactionsForDynStock.length;
        int transactionsIteratorIndex = firstBuyTransactionIndex;
        int stockPriceIteratorIndex = 0;
        int stockPriceLength = stockPrices.length;
        while (transactionsIteratorIndex + 1 < totalTransactionsLength &&
            stockPriceIteratorIndex < stockPriceLength) {
          double currentBuyPrice =
              transactionsForDynStock[transactionsIteratorIndex].stockPrice;
          double currentSellPrice =
              transactionsForDynStock[transactionsIteratorIndex + 1].stockPrice;
          List<FlSpot> spots = [];

          while (double.parse(stockPrices[stockPriceIteratorIndex]
                      .toStringAsFixed(2)) >=
                  currentBuyPrice &&
              double.parse(stockPrices[stockPriceIteratorIndex]
                      .toStringAsFixed(2)) <=
                  currentSellPrice &&
              stockPriceIteratorIndex < stockPriceLength) {
            // From currentBuyPrice to currentSellPrice within the time period, add all the prices to the line graph
            DateTime stockTime = DateTime.fromMillisecondsSinceEpoch(
                stockPricesTimeStamp[stockPriceIteratorIndex].toInt());
            DateTime buyTransactionTime = DateTime.fromMillisecondsSinceEpoch(
                transactionsForDynStock[transactionsIteratorIndex]
                    .transactionTime
                    .date);
            DateTime sellTransactionTime = DateTime.fromMillisecondsSinceEpoch(
                transactionsForDynStock[transactionsIteratorIndex + 1]
                    .transactionTime
                    .date);
            if (stockTime.compareTo(buyTransactionTime) >= 0 &&
                stockTime.compareTo(sellTransactionTime) <= 0) {
              spots.add(FlSpot(
                  stockPricesTimeStamp[stockPriceIteratorIndex].toDouble(),
                  stockPrices[stockPriceIteratorIndex]
                      .toDouble())); // Need to change x coordinate
              stockPriceIteratorIndex++;
            } else if (stockTime.compareTo(sellTransactionTime) > 0) {
              spots.add(FlSpot(
                  stockPricesTimeStamp[stockPriceIteratorIndex].toDouble(),
                  stockPrices[stockPriceIteratorIndex]
                      .toDouble())); // Need to change x coordinate
              lineCharts.add(LineChartBarData(
                spots: spots,
                isCurved: false,
                color: Colors.blue,
              ));
              break;
            }
          }
          transactionsIteratorIndex += 2;
        }
        setState(() {
          lineChartsBarData = lineCharts;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    if (!isLoaded) {
      parseDataForActualStockPriceChart();
      parseDataForDynStockPriceChart();
      setState(() {
        isLoaded = true;
      });
    }
    return Scaffold(
      body: StoreConnector<AppState, AppState>(
          converter: ((store) => store.state),
          builder: (context, state) {
            return Container(
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
                          lineBarsData: lineChartsBarData,
                          // [
                          // LineChartBarData(
                          //     dotData: FlDotData(show: false),
                          //     spots: actualStockChartPoints,
                          //     isCurved: false,
                          //     barWidth: 5,
                          //     color: Colors.green),
                          // LineChartBarData(
                          //     dotData: FlDotData(show: true),
                          //     spots: dynStockChartPoints,
                          //     isCurved: false,
                          //     barWidth: 5,
                          //     color: Colors.blue),
                          // ]
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
                                      timeString = '${time.day} ${time.hour}';
                                      break;
                                    case '1m':
                                      timeString = '${time.day} ${time.hour}';
                                      break;
                                    case '3m':
                                      timeString = '${time.month}-${time.day}';
                                      break;
                                    case '6m':
                                      timeString = '${time.month}-${time.day}';
                                      break;
                                    case '1y':
                                      timeString = '${time.month} ${time.day}';
                                      break;
                                  }
                                  return Container(child: Text(timeString));
                                },
                              ))))),
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
                                netReturnsForDynStock.toStringAsFixed(2),
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
                  ],
                ));
          }),
    );
  }
}
