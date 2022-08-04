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

void tickerDataMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetAllTickerDataAction) {
    store.state.allDynStocks.data.forEachIndexed((index, dynStock) async {
      TickerDataService()
          .getTickerData(dynStock.yFinStockCode)
          .then((response) {
        Map<String, TickerData> map = Map.from(store.state.allTickerData.data);
        map[dynStock.stockCode] = response;
        if (dynStock.lastTransactionType == 'BUY') {
          // Next step is to sell the stocks
          response.currentLocalMaximumPrice = max(
              max(response.currentLocalMaximumPrice, dynStock.lastTradedPrice),
              response.price.currentPrice ?? double.negativeInfinity);
          response.currentLocalMinimumPrice = double.infinity;
        } else if (dynStock.lastTransactionType == 'SELL') {
          // Next step is to buy the stocks
          response.currentLocalMinimumPrice = min(
              min(response.currentLocalMinimumPrice, dynStock.lastTradedPrice),
              response.price.currentPrice ?? double.infinity);
          response.currentLocalMaximumPrice = double.negativeInfinity;
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
        DateTime nextDayOfLastTransactionTime =
            lastTransactionTime.add(Duration(days: 1));
        String formattedNextDayOfLastTransactionTime =
            formatter.format(nextDayOfLastTransactionTime);
        lastTransactionTime =
            DateTime.parse(formattedNextDayOfLastTransactionTime);
        // SELL Logic
        if (dynStock.lastTransactionType == 'BUY' &&
            dynStock.stocksAvailableForTrade > 0) {
          if (now.compareTo(nextDayOfLastTransactionTime) >= 0) {
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
                        (response.currentLocalMaximumPrice) *
                            (1 - (dynStock.STPe / 100))) {
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
                        noOfStocks: dynStock.stocksAvailableForTrade,
                        stockCode: dynStock.stockCode,
                        stockPrice: response.price.currentPrice!)));
              }
              break;
            case 'Percentage':
              if (response.price.currentPrice != null &&
                  response.price.currentPrice! >=
                      (response.currentLocalMinimumPrice) *
                          (1 + (dynStock.STPe / 100))) {
                store.dispatch(CreateTransactionAction(
                    userId: appStore.state.userId,
                    instrumentToken: dynStock.instrumentToken,
                    dynStockId: dynStock.dynStockId.uuid,
                    body: TransactionBody(
                        transactionId: '',
                        type: 'BUY',
                        noOfStocks: dynStock.stocksAvailableForTrade,
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
