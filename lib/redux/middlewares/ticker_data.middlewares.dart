import 'dart:math';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/models/yahoo_finance_data.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/ticker_data.service.dart';
import 'package:redux/redux.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:yahoofin/yahoofin.dart';

double findLocalMaximaFromPreviousData(StockChart? chart) {
  if (chart == null ||
      chart.chartQuotes == null ||
      chart.chartQuotes!.high == null ||
      chart.chartQuotes!.high!.isEmpty) {
    return double.negativeInfinity;
  }
  return double.negativeInfinity;
}

double findLocalMinimaFromPreviousData(StockChart? chart) {
  if (chart == null ||
      chart.chartQuotes == null ||
      chart.chartQuotes!.low == null ||
      chart.chartQuotes!.low!.isEmpty) {
    return double.infinity;
  }
  return double.infinity;
}

void tickerDataMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetAllTickerDataAction) {
    DateTime now = DateTime.now();
    bool fetchChartHistory = false;
    if (now.minute < 1 && now.second < 20) {
      fetchChartHistory = true;
    }

    store.state.allDynStocks.data.forEachIndexed((index, dynStock) async {
      bool orderPlaced = false;
      String orderType = '';
      TickerDataService()
          .getTickerData(dynStock.yFinStockCode,
              fetchChartHistory: fetchChartHistory,
              currentLocalMaximumPrice: store.state.allTickerData
                      .data[dynStock.stockCode]?.currentLocalMaximumPrice ??
                  double.negativeInfinity,
              currentLocalMinimumPrice: store.state.allTickerData
                      .data[dynStock.stockCode]?.currentLocalMinimumPrice ??
                  double.infinity)
          .then((response) {
        DateTime now = DateTime.now();
        bool stockMarketClosed = (now.hour < 9) ||
            now.hour >= 16 ||
            (now.hour == 9 && now.minute < 15) ||
            (now.hour == 15 && now.minute > 30) ||
            (now.weekday > 5);
        DateFormat formatter = DateFormat('yyyy-MM-dd');
        String formattedNow = formatter.format(now);
        now = DateTime.parse(formattedNow);
        DateTime lastTransactionTime = DateTime.fromMillisecondsSinceEpoch(
            dynStock.lastTransactionTime!.date);

        Map<String, TickerData> map = Map.from(store.state.allTickerData.data);
        map[dynStock.stockCode] = response;
        if (dynStock.lastTransactionType == 'BUY') {
          // Next step is to sell the stocks
          if (response.currentLocalMaximumPrice == double.negativeInfinity) {
            // Means app is restarted, so compare with previous day's local maxima
            double possibleLocalMaximaFromYesterday =
                findLocalMaximaFromPreviousData(response.chart);
            possibleLocalMaximaFromYesterday = double.parse(
                possibleLocalMaximaFromYesterday.toStringAsFixed(2));
            double lastTradedPriceCorrected = dynStock.lastTradedPrice;
            // if (dynStock.DSTPUnit == EDSTPUnit.Price.name) {
            //   // Add the STPr value for localMaxima computation
            //   lastTradedPriceCorrected =
            //       dynStock.lastTradedPrice + dynStock.STPr;
            // } else {
            //   // Add the STPe value for localMaxima computation
            //   lastTradedPriceCorrected =
            //       dynStock.lastTradedPrice * (1 + (dynStock.STPe / 100.00));
            // }
            // // Define a tolerance amount so that the trade doesn't repeatedly happen at the same time
            // lastTradedPriceCorrected = lastTradedPriceCorrected -
            //     dynStock.tolerance / dynStock.stocksAvailableForTrade;
            response.currentLocalMaximumPrice = max(
                max(
                    max(response.currentLocalMaximumPrice,
                        lastTradedPriceCorrected),
                    response.price.currentPrice ?? double.negativeInfinity),
                possibleLocalMaximaFromYesterday);
            response.currentLocalMinimumPrice =
                response.currentLocalMaximumPrice;
          } else {
            // App is running, so no need to compare with previous day's local maxima
            double lastTradedPriceCorrected = dynStock.lastTradedPrice;
            // if (dynStock.DSTPUnit == EDSTPUnit.Price.name) {
            //   lastTradedPriceCorrected =
            //       dynStock.lastTradedPrice + dynStock.STPr;
            // } else {
            //   lastTradedPriceCorrected =
            //       dynStock.lastTradedPrice * (1 + (dynStock.STPe / 100.00));
            // }
            // // Define a tolerance amount so that the trade doesn't repeatedly happen at the same time
            // lastTradedPriceCorrected = lastTradedPriceCorrected -
            //     dynStock.tolerance / dynStock.stocksAvailableForTrade;
            response.currentLocalMaximumPrice = max(
                max(response.currentLocalMaximumPrice,
                    lastTradedPriceCorrected),
                response.price.currentPrice ?? double.negativeInfinity);
            response.currentLocalMinimumPrice =
                response.currentLocalMaximumPrice;
          }
        } else if (dynStock.lastTransactionType == 'SELL') {
          // Next step is to buy the stocks
          if (response.currentLocalMinimumPrice == double.infinity) {
            // Means app is restarted, so compare with previous day's local minima
            double possibleLocalMinimaFromYesterday =
                findLocalMinimaFromPreviousData(response.chart);
            possibleLocalMinimaFromYesterday = double.parse(
                (possibleLocalMinimaFromYesterday).toStringAsFixed(2));
            double lastTradedPriceCorrected = dynStock.lastTradedPrice;
            // if (dynStock.DSTPUnit == EDSTPUnit.Price.name) {
            //   // Subtract the BTPr value
            //   lastTradedPriceCorrected =
            //       dynStock.lastTradedPrice - dynStock.BTPr;
            // } else {
            //   // Subtract the BTPe value
            //   lastTradedPriceCorrected =
            //       dynStock.lastTradedPrice * (1 - (dynStock.BTPe / 100.00));
            // }
            // Define a tolerance amount so that the trade doesn't repeatedly happen at the same time
            // lastTradedPriceCorrected = lastTradedPriceCorrected +
            //     dynStock.tolerance / dynStock.stocksAvailableForTrade;
            response.currentLocalMinimumPrice = min(
                min(
                    min(response.currentLocalMinimumPrice,
                        lastTradedPriceCorrected),
                    response.price.currentPrice ?? double.infinity),
                possibleLocalMinimaFromYesterday);
            response.currentLocalMaximumPrice =
                response.currentLocalMinimumPrice;
          } else {
            // App is running, so no need to compare with previous day's local minima
            double lastTradedPriceCorrected = dynStock.lastTradedPrice;
            // if (dynStock.DSTPUnit == EDSTPUnit.Price.name) {
            //   lastTradedPriceCorrected =
            //       dynStock.lastTradedPrice - dynStock.BTPr;
            // } else {
            //   lastTradedPriceCorrected =
            //       dynStock.lastTradedPrice * (1 - (dynStock.BTPe / 100.00));
            // }
            // // Define a tolerance amount so that the trade doesn't repeatedly happen at the same time
            // lastTradedPriceCorrected = lastTradedPriceCorrected +
            //     dynStock.tolerance / dynStock.stocksAvailableForTrade;
            response.currentLocalMinimumPrice = min(
                min(response.currentLocalMinimumPrice,
                    lastTradedPriceCorrected),
                response.price.currentPrice ?? double.infinity);
            response.currentLocalMaximumPrice =
                response.currentLocalMinimumPrice;
          }
        }

        store.dispatch(GetAllTickerDataSuccessAction(allTickerData: map));
        lastTransactionTime = lastTransactionTime.subtract(Duration(
            hours: lastTransactionTime.hour,
            minutes: lastTransactionTime.minute,
            seconds: lastTransactionTime.second,
            milliseconds: lastTransactionTime.millisecond));
        DateTime secondNextDayOfLastTransactionTime =
            lastTransactionTime.add(Duration(days: 2));
        String formattedsecondNextDayOfLastTransactionTime =
            formatter.format(secondNextDayOfLastTransactionTime);
        lastTransactionTime =
            DateTime.parse(formattedsecondNextDayOfLastTransactionTime);

        if (!stockMarketClosed &&
            (store.state.transactionsCreateState.data[dynStock.stockCode] !=
                null) &&
            !(store.state.transactionsCreateState.data[dynStock.stockCode]!
                .creating) &&
            !(pauseTransactions[dynStock.stockCode] == true)) {
          // SELL Logic
          if (dynStock.lastTransactionType == 'BUY' &&
              !(dynStock.stallTransactions)) {
            if ((now.compareTo(secondNextDayOfLastTransactionTime) >= 0 &&
                    dynStock.stockType == EStockType.BE.name) ||
                dynStock.stockType != EStockType.BE.name) {
              switch (dynStock.DSTPUnit) {
                case 'Price':
                  if (((response.price.currentPrice! -
                                  dynStock.lastTradedPrice) *
                              dynStock.noOfStocks <=
                          dynStock.HETolerance) &&
                      ((response.price.currentPrice! -
                                  dynStock.lastTradedPrice) *
                              dynStock.noOfStocks >=
                          dynStock.LETolerance)) {
                    orderPlaced = true;
                    orderType = 'SELL';
                    store.dispatch(CreateTransactionAction(
                        userId: appStore.state.userId,
                        instrumentToken: dynStock.instrumentToken,
                        dynStockId: dynStock.dynStockId.uuid,
                        stockCode: dynStock.stockCode,
                        stockOrderType: EStockOrderType.Limit.name,
                        body: TransactionBody(
                          transactionId: '',
                          type: 'SELL',
                          noOfStocks: dynStock.stocksAvailableForTrade == 0
                              ? dynStock.noOfStocks
                              : dynStock.stocksAvailableForTrade,
                          stockCode: dynStock.stockCode,
                          stockPrice: response.price.currentPrice!,
                        )));
                  } else if (response.price.currentPrice != null &&
                      (response.price.currentPrice! <=
                          response.currentLocalMaximumPrice - dynStock.STPr)) {
                    orderPlaced = true;
                    orderType = 'SELL';
                    store.dispatch(CreateTransactionAction(
                        userId: appStore.state.userId,
                        instrumentToken: dynStock.instrumentToken,
                        stockOrderType: EStockOrderType.Limit.name,
                        dynStockId: dynStock.dynStockId.uuid,
                        stockCode: dynStock.stockCode,
                        body: TransactionBody(
                            transactionId: '',
                            type: 'SELL',
                            noOfStocks: dynStock.stocksAvailableForTrade == 0
                                ? dynStock.noOfStocks
                                : dynStock.stocksAvailableForTrade,
                            stockCode: dynStock.stockCode,
                            stockPrice: response.price.currentPrice!)));
                  }
                  break;
                case 'Percentage':
                  if (((response.price.currentPrice! -
                                  dynStock.lastTradedPrice) *
                              dynStock.noOfStocks <=
                          dynStock.HETolerance) &&
                      ((response.price.currentPrice! -
                                  dynStock.lastTradedPrice) *
                              dynStock.noOfStocks >=
                          dynStock.LETolerance)) {
                    orderPlaced = true;
                    orderType = 'SELL';
                    store.dispatch(CreateTransactionAction(
                        userId: appStore.state.userId,
                        instrumentToken: dynStock.instrumentToken,
                        dynStockId: dynStock.dynStockId.uuid,
                        stockCode: dynStock.stockCode,
                        stockOrderType: EStockOrderType.Limit.name,
                        body: TransactionBody(
                          transactionId: '',
                          type: 'SELL',
                          noOfStocks: dynStock.stocksAvailableForTrade == 0
                              ? dynStock.noOfStocks
                              : dynStock.stocksAvailableForTrade,
                          stockCode: dynStock.stockCode,
                          stockPrice: response.price.currentPrice!,
                        )));
                  } else if (response.price.currentPrice != null &&
                      (response.price.currentPrice! <=
                          double.parse(((response.currentLocalMaximumPrice) *
                                  (1 - (dynStock.STPe / 100)))
                              .toStringAsFixed(2)))) {
                    orderPlaced = true;
                    orderType = 'SELL';
                    store.dispatch(CreateTransactionAction(
                        userId: appStore.state.userId,
                        instrumentToken: dynStock.instrumentToken,
                        stockOrderType: EStockOrderType.Limit.name,
                        dynStockId: dynStock.dynStockId.uuid,
                        stockCode: dynStock.stockCode,
                        body: TransactionBody(
                            transactionId: '',
                            type: 'SELL',
                            noOfStocks: dynStock.stocksAvailableForTrade == 0
                                ? dynStock.noOfStocks
                                : dynStock.stocksAvailableForTrade,
                            stockCode: dynStock.stockCode,
                            stockPrice: response.price.currentPrice!)));
                  }
                  break;
              }
            }
          }
          // BUY Logic
          if (dynStock.lastTransactionType == 'SELL' &&
              !(dynStock.stallTransactions)) {
            switch (dynStock.DSTPUnit) {
              case 'Price':
                if (((dynStock.lastTradedPrice - response.price.currentPrice!) *
                            dynStock.noOfStocks <=
                        dynStock.HETolerance) &&
                    ((dynStock.lastTradedPrice - response.price.currentPrice!) *
                            dynStock.noOfStocks >=
                        dynStock.LETolerance)) {
                  orderPlaced = true;
                  orderType = 'BUY';
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      dynStockId: dynStock.dynStockId.uuid,
                      stockCode: dynStock.stockCode,
                      stockOrderType: EStockOrderType.Limit.name,
                      body: TransactionBody(
                        transactionId: '',
                        type: 'BUY',
                        noOfStocks: (dynStock.noOfStocks -
                            dynStock.stocksAvailableForTrade),
                        stockCode: dynStock.stockCode,
                        stockPrice: response.price.currentPrice!,
                      )));
                } else if (response.price.currentPrice != null &&
                    (response.price.currentPrice! >=
                        response.currentLocalMinimumPrice + dynStock.BTPr)) {
                  orderPlaced = true;
                  orderType = 'BUY';
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      stockOrderType: EStockOrderType.Limit.name,
                      dynStockId: dynStock.dynStockId.uuid,
                      stockCode: dynStock.stockCode,
                      body: TransactionBody(
                          transactionId: '',
                          type: 'BUY',
                          noOfStocks: (dynStock.noOfStocks -
                              dynStock.stocksAvailableForTrade),
                          stockCode: dynStock.stockCode,
                          stockPrice: response.price.currentPrice!)));
                }
                break;
              case 'Percentage':
                if (((dynStock.lastTradedPrice - response.price.currentPrice!) *
                            dynStock.noOfStocks <=
                        dynStock.HETolerance) &&
                    ((dynStock.lastTradedPrice - response.price.currentPrice!) *
                            dynStock.noOfStocks >=
                        dynStock.LETolerance)) {
                  orderPlaced = true;
                  orderType = 'BUY';
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      dynStockId: dynStock.dynStockId.uuid,
                      stockOrderType: EStockOrderType.Limit.name,
                      stockCode: dynStock.stockCode,
                      body: TransactionBody(
                        transactionId: '',
                        type: 'BUY',
                        noOfStocks: (dynStock.noOfStocks -
                            dynStock.stocksAvailableForTrade),
                        stockCode: dynStock.stockCode,
                        stockPrice: response.price.currentPrice!,
                      )));
                } else if (response.price.currentPrice != null &&
                    (response.price.currentPrice! >=
                        double.parse(((response.currentLocalMinimumPrice) *
                                (1 + (dynStock.BTPe / 100)))
                            .toStringAsFixed(2)))) {
                  orderPlaced = true;
                  orderType = 'BUY';
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      dynStockId: dynStock.dynStockId.uuid,
                      stockOrderType: EStockOrderType.Limit.name,
                      stockCode: dynStock.stockCode,
                      body: TransactionBody(
                          transactionId: '',
                          type: 'BUY',
                          noOfStocks: (dynStock.noOfStocks -
                              dynStock.stocksAvailableForTrade),
                          stockCode: dynStock.stockCode,
                          stockPrice: response.price.currentPrice!)));
                }
                break;
            }
          }
        }

        // if (orderPlaced) {
        //   map[dynStock.stockCode]?.currentLocalMaximumPrice =
        //       response.price.currentPrice!;
        //   map[dynStock.stockCode]?.currentLocalMinimumPrice =
        //       response.price.currentPrice!;
        // }
      }).catchError((error) {
        print(error);
        store.dispatch(GetAllTickerDataFailAction(error: error));
      });
    });
  }
  next(action);
}
