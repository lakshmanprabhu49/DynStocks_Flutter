import 'dart:math';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/models/yahoo_finance_data.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/redux/state/ticker_data.state.dart';
import 'package:dynstocks/services/transactions.service.dart';
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
  num localMaximum = chart.chartQuotes!.high!.last;
  List<num>? high = chart.chartQuotes!.high;
  int index = chart.chartQuotes!.high!.length - 1;
  while (index > 0) {
    if ((high![index - 1] < high[index]) && (high[index + 1] < high[index])) {
      localMaximum = high[index];
      break;
    }
    index--;
  }
  return localMaximum as double;
}

double findLocalMinimaFromPreviousData(StockChart? chart) {
  if (chart == null ||
      chart.chartQuotes == null ||
      chart.chartQuotes!.low == null ||
      chart.chartQuotes!.low!.isEmpty) {
    return double.infinity;
  }
  num localMinimum = chart.chartQuotes!.low!.last;
  List<num>? low = chart.chartQuotes!.low;
  int index = chart.chartQuotes!.low!.length - 1;
  while (index > 0) {
    if ((low![index - 1] > low[index]) && (low[index + 1] > low[index])) {
      localMinimum = low[index];
      break;
    }
    index--;
  }
  return localMinimum as double;
}

void tickerDataMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetAllTickerDataAction) {
    store.state.allDynStocks.data.forEachIndexed((index, dynStock) async {
      TickerDataService()
          .getTickerData(dynStock.yFinStockCode,
              currentLocalMaximumPrice: store.state.allTickerData
                      .data[dynStock.stockCode]?.currentLocalMaximumPrice ??
                  double.negativeInfinity,
              currentLocalMinimumPrice: store.state.allTickerData
                      .data[dynStock.stockCode]?.currentLocalMinimumPrice ??
                  double.infinity)
          .then((response) {
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
            response.currentLocalMaximumPrice = max(
                max(
                    max(response.currentLocalMaximumPrice,
                        dynStock.lastTradedPrice),
                    response.price.currentPrice ?? double.negativeInfinity),
                possibleLocalMaximaFromYesterday);
            response.currentLocalMinimumPrice =
                response.currentLocalMaximumPrice;
          } else {
            // App is running, so no need to compare with previous day's local maxima
            response.currentLocalMaximumPrice = max(
                max(response.currentLocalMaximumPrice,
                    dynStock.lastTradedPrice),
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
            response.currentLocalMinimumPrice = min(
                min(
                    min(response.currentLocalMinimumPrice,
                        dynStock.lastTradedPrice),
                    response.price.currentPrice ?? double.infinity),
                possibleLocalMinimaFromYesterday);
            response.currentLocalMaximumPrice =
                response.currentLocalMinimumPrice;
          } else {
            // App is running, so no need to compare with previous day's local minima
            response.currentLocalMinimumPrice = min(
                min(response.currentLocalMinimumPrice,
                    dynStock.lastTradedPrice),
                response.price.currentPrice ?? double.infinity);
            response.currentLocalMaximumPrice =
                response.currentLocalMinimumPrice;
          }
        }

        DateTime now = DateTime.now();
        DateFormat formatter = DateFormat('yyyy-MM-dd');
        String formattedNow = formatter.format(now);
        now = DateTime.parse(formattedNow);

        DateTime lastTransactionTime = DateTime.fromMillisecondsSinceEpoch(
            dynStock.lastTransactionTime!.date);
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
        // SELL Logic
        if (dynStock.lastTransactionType == 'BUY' &&
            dynStock.stocksAvailableForTrade > 0) {
          if ((now.compareTo(secondNextDayOfLastTransactionTime) >= 0 &&
                  dynStock.stockType == EStockType.BE.name) ||
              dynStock.stockType != EStockType.BE.name) {
            switch (dynStock.DSTPUnit) {
              case 'Price':
                if (response.price.currentPrice != null &&
                    response.price.currentPrice! <=
                        response.currentLocalMaximumPrice - dynStock.STPr) {
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      dynStockId: dynStock.dynStockId.uuid,
                      body: TransactionBody(
                          transactionId: '',
                          type: 'SELL',
                          noOfStocks: dynStock.stocksAvailableForTrade,
                          stockCode: dynStock.stockCode,
                          stockPrice: response.price.currentPrice!)));
                }
                break;
              case 'Percentage':
                if (response.price.currentPrice != null &&
                    response.price.currentPrice! <=
                        double.parse(((response.currentLocalMaximumPrice) *
                                (1 - (dynStock.STPe / 100)))
                            .toStringAsFixed(2))) {
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      dynStockId: dynStock.dynStockId.uuid,
                      body: TransactionBody(
                          transactionId: '',
                          type: 'SELL',
                          noOfStocks: dynStock.stocksAvailableForTrade,
                          stockCode: dynStock.stockCode,
                          stockPrice: response.price.currentPrice!)));
                }
                break;
            }
          }
        }
        // BUY Logic
        if (dynStock.lastTransactionType == 'SELL' &&
            dynStock.stocksAvailableForTrade == 0) {
          switch (dynStock.DSTPUnit) {
            case 'Price':
              if (response.price.currentPrice != null &&
                  response.price.currentPrice! >=
                      response.currentLocalMinimumPrice + dynStock.BTPr) {
                store.dispatch(CreateTransactionAction(
                    userId: appStore.state.userId,
                    instrumentToken: dynStock.instrumentToken,
                    dynStockId: dynStock.dynStockId.uuid,
                    body: TransactionBody(
                        transactionId: '',
                        type: 'BUY',
                        noOfStocks: dynStock.noOfStocks,
                        stockCode: dynStock.stockCode,
                        stockPrice: response.price.currentPrice!)));
              }
              break;
            case 'Percentage':
              if (response.price.currentPrice != null &&
                  response.price.currentPrice! >=
                      double.parse(((response.currentLocalMinimumPrice) *
                              (1 + (dynStock.BTPe / 100)))
                          .toStringAsFixed(2))) {
                store.dispatch(CreateTransactionAction(
                    userId: appStore.state.userId,
                    instrumentToken: dynStock.instrumentToken,
                    dynStockId: dynStock.dynStockId.uuid,
                    body: TransactionBody(
                        transactionId: '',
                        type: 'BUY',
                        noOfStocks: dynStock.noOfStocks,
                        stockCode: dynStock.stockCode,
                        stockPrice: response.price.currentPrice!)));
              }
              break;
          }
        }
        store.dispatch(GetAllTickerDataSuccessAction(allTickerData: map));
      }).catchError((error) {
        store.dispatch(GetAllTickerDataFailAction(error: error));
      });
    });
  }
  next(action);
}
