import 'dart:math';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/dyn_stocks_real_time_price.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/models/yahoo_finance_data.dart';
import 'package:dynstocks/redux/actions/dyn_stocks_real_time_price.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/dynstocks_real_time_price.service.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/gmail_error_message.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:dynstocks/static/last_dispatched_order_time.dart';
import 'package:redux/redux.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:yahoofin/yahoofin.dart';

void tickerDataMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetAllTickerDataAction) {
    DateTime now = DateTime.now();
    bool fetchChartHistory = false;
    if (now.minute < 1 && now.second < 20) {
      fetchChartHistory = true;
    }

    List<String> quotesInstrumentTokens = [];

    store.state.allDynStocks.data.forEachIndexed((index, dynStock) {
      quotesInstrumentTokens.add(dynStock.instrumentToken);
    });

    String hyphenatedQuotesInstrumentToken = quotesInstrumentTokens.join("-");

    // Quotes response will be in the order of dynstocks
    KotakStockApiQuotesResponse quotesResponse = await KotakStockAPIService()
        .getQuotes(store.state.userId, hyphenatedQuotesInstrumentToken,
            store.state.accessCode);

    List<StockDetail> updatedRealTimePrice = [];

    quotesResponse.success.forEachIndexed((index, stockQuote) {
      bool orderPlaced = false;
      StockDetail realTimePrice =
          store.state.dynStocksRealTimePriceState.data[index];
      DynStock dynStock = store.state.allDynStocks.data
              .firstWhere((element) => element.stockCode == stockQuote.stkName)
          as DynStock;
      String orderType = '';

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
      TickerData currentTickerData = TickerData(stockQuote: stockQuote);
      double currentLocalMaximumPrice = max(currentTickerData.stockQuote.ltp,
          realTimePrice.currentLocalMaximumPrice);
      double currentLocalMinimumPrice = min(currentTickerData.stockQuote.ltp,
          realTimePrice.currentLocalMinimumPrice);
      map[dynStock.stockCode] = currentTickerData;
      // Here we are only setting localMaximum and localMinimum Price
      if (dynStock.lastTransactionType == 'BUY') {
        // Next step is to sell the stocks
        // App is running, so no need to compare with previous day's local maxima
        double lastTradedPriceCorrected = dynStock.lastTradedPrice;
        currentLocalMaximumPrice = max(
            max(currentLocalMaximumPrice, lastTradedPriceCorrected),
            currentTickerData.stockQuote.lowPrice);
        currentLocalMinimumPrice = currentLocalMaximumPrice;
      } else if (dynStock.lastTransactionType == 'SELL') {
        // Next step is to buy the stocks

        // App is running, so no need to compare with previous day's local minima
        double lastTradedPriceCorrected = dynStock.lastTradedPrice;
        currentLocalMinimumPrice = min(
            min(currentLocalMinimumPrice, lastTradedPriceCorrected),
            currentTickerData.stockQuote.lowPrice);
        currentLocalMaximumPrice = currentLocalMinimumPrice;
      }

      store.dispatch(GetAllTickerDataSuccessAction(allTickerData: map));
      lastTransactionTime = lastTransactionTime.subtract(Duration(
          hours: lastTransactionTime.hour,
          minutes: lastTransactionTime.minute,
          seconds: lastTransactionTime.second,
          milliseconds: lastTransactionTime.millisecond));
      DateTime secondNextDayOfLastTransactionTime =
          lastTransactionTime.add(const Duration(days: 2));
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
        if (!LastDispatchedOrderTime.data.containsKey(dynStock.stockCode)) {
          LastDispatchedOrderTime.data[dynStock.stockCode] = DateTime(2020);
        }
        DateTime lastDispatchedOrderTime =
            LastDispatchedOrderTime.data[dynStock.stockCode] as DateTime;
        DateTime now = DateTime.now();
        Duration difference = now.difference(lastDispatchedOrderTime);
        // SELL Logic
        if (dynStock.lastTransactionType == 'BUY' &&
            !(dynStock.stallTransactions)) {
          if ((now.compareTo(secondNextDayOfLastTransactionTime) >= 0 &&
                  dynStock.stockType == EStockType.BE.name) ||
              dynStock.stockType != EStockType.BE.name) {
            switch (dynStock.DSTPUnit) {
              case 'Price':
                if (((dynStock.lastTradedPrice -
                            currentTickerData.stockQuote.ltp) <=
                        dynStock.HETolerance) &&
                    ((dynStock.lastTradedPrice -
                            currentTickerData.stockQuote.ltp) >=
                        dynStock.LETolerance) &&
                    (difference.inMinutes >= 1)) {
                  orderPlaced = true;

                  orderType = 'SELL';
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      dynStockId: dynStock.dynStockId,
                      stockCode: dynStock.stockCode,
                      stockOrderType: EStockOrderType.Market.name,
                      body: TransactionBody(
                        transactionId: '',
                        type: 'SELL',
                        noOfStocks: dynStock.stocksAvailableForTrade == 0
                            ? dynStock.noOfStocks
                            : dynStock.stocksAvailableForTrade,
                        stockCode: dynStock.stockCode,
                        stockPrice: 0,
                      )));
                } else if ((currentTickerData.stockQuote.ltp <=
                        currentLocalMaximumPrice - dynStock.STPr) &&
                    (difference.inMinutes >= 1)) {
                  orderPlaced = true;

                  orderType = 'SELL';
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      stockOrderType: EStockOrderType.Market.name,
                      dynStockId: dynStock.dynStockId,
                      stockCode: dynStock.stockCode,
                      body: TransactionBody(
                        transactionId: '',
                        type: 'SELL',
                        noOfStocks: dynStock.stocksAvailableForTrade == 0
                            ? dynStock.noOfStocks
                            : dynStock.stocksAvailableForTrade,
                        stockCode: dynStock.stockCode,
                        stockPrice: 0,
                      )));
                }
                break;
              case 'Percentage':
                if (((dynStock.lastTradedPrice -
                            currentTickerData.stockQuote.ltp) <=
                        dynStock.HETolerance) &&
                    ((dynStock.lastTradedPrice -
                            currentTickerData.stockQuote.ltp) >=
                        dynStock.LETolerance) &&
                    (difference.inMinutes >= 1)) {
                  orderPlaced = true;

                  orderType = 'SELL';
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      dynStockId: dynStock.dynStockId,
                      stockCode: dynStock.stockCode,
                      stockOrderType: EStockOrderType.Market.name,
                      body: TransactionBody(
                        transactionId: '',
                        type: 'SELL',
                        noOfStocks: dynStock.stocksAvailableForTrade == 0
                            ? dynStock.noOfStocks
                            : dynStock.stocksAvailableForTrade,
                        stockCode: dynStock.stockCode,
                        stockPrice: 0,
                      )));
                } else if ((currentTickerData.stockQuote.ltp <=
                        double.parse(((currentLocalMaximumPrice) *
                                (1 - (dynStock.STPe / 100)))
                            .toStringAsFixed(2))) &&
                    (difference.inMinutes >= 1)) {
                  orderPlaced = true;

                  orderType = 'SELL';
                  store.dispatch(CreateTransactionAction(
                      userId: appStore.state.userId,
                      instrumentToken: dynStock.instrumentToken,
                      stockOrderType: EStockOrderType.Market.name,
                      dynStockId: dynStock.dynStockId,
                      stockCode: dynStock.stockCode,
                      body: TransactionBody(
                        transactionId: '',
                        type: 'SELL',
                        noOfStocks: dynStock.stocksAvailableForTrade == 0
                            ? dynStock.noOfStocks
                            : dynStock.stocksAvailableForTrade,
                        stockCode: dynStock.stockCode,
                        stockPrice: 0,
                      )));
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
              if (((currentTickerData.stockQuote.ltp -
                          dynStock.lastTradedPrice) <=
                      dynStock.HETolerance) &&
                  ((currentTickerData.stockQuote.ltp -
                          dynStock.lastTradedPrice) >=
                      dynStock.LETolerance) &&
                  (difference.inMinutes >= 1)) {
                orderPlaced = true;

                orderType = 'BUY';
                store.dispatch(CreateTransactionAction(
                    userId: appStore.state.userId,
                    instrumentToken: dynStock.instrumentToken,
                    dynStockId: dynStock.dynStockId,
                    stockCode: dynStock.stockCode,
                    stockOrderType: EStockOrderType.Market.name,
                    body: TransactionBody(
                      transactionId: '',
                      type: 'BUY',
                      noOfStocks: (dynStock.noOfStocks -
                          dynStock.stocksAvailableForTrade),
                      stockCode: dynStock.stockCode,
                      stockPrice: 0,
                    )));
              } else if ((currentTickerData.stockQuote.ltp >=
                      currentLocalMinimumPrice + dynStock.BTPr) &&
                  (difference.inMinutes >= 1)) {
                orderPlaced = true;

                orderType = 'BUY';
                store.dispatch(CreateTransactionAction(
                    userId: appStore.state.userId,
                    instrumentToken: dynStock.instrumentToken,
                    stockOrderType: EStockOrderType.Market.name,
                    dynStockId: dynStock.dynStockId,
                    stockCode: dynStock.stockCode,
                    body: TransactionBody(
                      transactionId: '',
                      type: 'BUY',
                      noOfStocks: (dynStock.noOfStocks -
                          dynStock.stocksAvailableForTrade),
                      stockCode: dynStock.stockCode,
                      stockPrice: 0,
                    )));
              }
              break;
            case 'Percentage':
              if (((currentTickerData.stockQuote.ltp -
                          dynStock.lastTradedPrice) <=
                      dynStock.HETolerance) &&
                  ((currentTickerData.stockQuote.ltp -
                          dynStock.lastTradedPrice) >=
                      dynStock.LETolerance) &&
                  (difference.inMinutes >= 1)) {
                orderPlaced = true;

                orderType = 'BUY';
                store.dispatch(CreateTransactionAction(
                    userId: appStore.state.userId,
                    instrumentToken: dynStock.instrumentToken,
                    dynStockId: dynStock.dynStockId,
                    stockOrderType: EStockOrderType.Market.name,
                    stockCode: dynStock.stockCode,
                    body: TransactionBody(
                      transactionId: '',
                      type: 'BUY',
                      noOfStocks: (dynStock.noOfStocks -
                          dynStock.stocksAvailableForTrade),
                      stockCode: dynStock.stockCode,
                      stockPrice: 0,
                    )));
              } else if ((currentTickerData.stockQuote.ltp >=
                      double.parse(((currentLocalMinimumPrice) *
                              (1 + (dynStock.BTPe / 100)))
                          .toStringAsFixed(2))) &&
                  (difference.inMinutes >= 1)) {
                orderPlaced = true;

                orderType = 'BUY';
                store.dispatch(CreateTransactionAction(
                    userId: appStore.state.userId,
                    instrumentToken: dynStock.instrumentToken,
                    dynStockId: dynStock.dynStockId,
                    stockOrderType: EStockOrderType.Market.name,
                    stockCode: dynStock.stockCode,
                    body: TransactionBody(
                      transactionId: '',
                      type: 'BUY',
                      noOfStocks: (dynStock.noOfStocks -
                          dynStock.stocksAvailableForTrade),
                      stockCode: dynStock.stockCode,
                      stockPrice: 0,
                    )));
              }
              break;
          }
        }
      }

      // Check if data is empty already
      if (currentLocalMaximumPrice != realTimePrice.currentLocalMaximumPrice ||
          currentLocalMinimumPrice != realTimePrice.currentLocalMinimumPrice) {
        updatedRealTimePrice.add(StockDetail(
            stockCode: dynStock.stockCode,
            currentLocalMaximumPrice: currentLocalMaximumPrice,
            currentLocalMinimumPrice: currentLocalMinimumPrice));
      }
    });

    // Update local maxima and local minima in real time price DB if changed
    if (updatedRealTimePrice.isNotEmpty) {
      store.dispatch(UpdateDynStocksRealTimePriceAction(
          userId: store.state.userId, stockDetails: updatedRealTimePrice));
    }
    // store.state.allDynStocks.data.forEachIndexed((index, dynStock) async {
    //   bool orderPlaced = false;
    //   String orderType = '';
    //   TickerDataService()
    //       .getTickerData(dynStock.yFinStockCode,
    //           fetchChartHistory: fetchChartHistory,
    //           currentLocalMaximumPrice: store.state.allTickerData
    //                   .data[dynStock.stockCode]?.currentLocalMaximumPrice ??
    //               double.negativeInfinity,
    //           currentLocalMinimumPrice: store.state.allTickerData
    //                   .data[dynStock.stockCode]?.currentLocalMinimumPrice ??
    //               double.infinity)
    //       .then((currentTickerData) {
    //     DateTime now = DateTime.now();
    //     bool stockMarketClosed = (now.hour < 9) ||
    //         now.hour >= 16 ||
    //         (now.hour == 9 && now.minute < 15) ||
    //         (now.hour == 15 && now.minute > 30) ||
    //         (now.weekday > 5);
    //     DateFormat formatter = DateFormat('yyyy-MM-dd');
    //     String formattedNow = formatter.format(now);
    //     now = DateTime.parse(formattedNow);
    //     DateTime lastTransactionTime = DateTime.fromMillisecondsSinceEpoch(
    //         dynStock.lastTransactionTime!.date);

    //     Map<String, TickerData> map = Map.from(store.state.allTickerData.data);
    //     map[dynStock.stockCode] = currentTickerData;
    //     if (dynStock.lastTransactionType == 'BUY') {
    //       // Next step is to sell the stocks
    //       if (currentTickerData.currentLocalMaximumPrice == double.negativeInfinity) {
    //         // Means app is restarted, so compare with previous day's local maxima
    //         double possibleLocalMaximaFromYesterday =
    //             findLocalMaximaFromPreviousData(currentTickerData.chart);
    //         possibleLocalMaximaFromYesterday = double.parse(
    //             possibleLocalMaximaFromYesterday.toStringAsFixed(2));
    //         double lastTradedPriceCorrected = dynStock.lastTradedPrice;
    //         currentTickerData.currentLocalMaximumPrice = max(
    //             max(
    //                 max(currentTickerData.currentLocalMaximumPrice,
    //                     lastTradedPriceCorrected),
    //                 currentTickerData.price.currentPrice ?? double.negativeInfinity),
    //             possibleLocalMaximaFromYesterday);
    //         currentTickerData.currentLocalMinimumPrice =
    //             currentTickerData.currentLocalMaximumPrice;
    //       } else {
    //         // App is running, so no need to compare with previous day's local maxima
    //         double lastTradedPriceCorrected = dynStock.lastTradedPrice;
    //         currentTickerData.currentLocalMaximumPrice = max(
    //             max(currentTickerData.currentLocalMaximumPrice,
    //                 lastTradedPriceCorrected),
    //             currentTickerData.price.currentPrice ?? double.negativeInfinity);
    //         currentTickerData.currentLocalMinimumPrice =
    //             currentTickerData.currentLocalMaximumPrice;
    //       }
    //     } else if (dynStock.lastTransactionType == 'SELL') {
    //       // Next step is to buy the stocks
    //       if (currentTickerData.currentLocalMinimumPrice == double.infinity) {
    //         // Means app is restarted, so compare with previous day's local minima
    //         double possibleLocalMinimaFromYesterday =
    //             findLocalMinimaFromPreviousData(currentTickerData.chart);
    //         possibleLocalMinimaFromYesterday = double.parse(
    //             (possibleLocalMinimaFromYesterday).toStringAsFixed(2));
    //         double lastTradedPriceCorrected = dynStock.lastTradedPrice;
    //         currentTickerData.currentLocalMinimumPrice = min(
    //             min(
    //                 min(currentTickerData.currentLocalMinimumPrice,
    //                     lastTradedPriceCorrected),
    //                 currentTickerData.price.currentPrice ?? double.infinity),
    //             possibleLocalMinimaFromYesterday);
    //         currentTickerData.currentLocalMaximumPrice =
    //             currentTickerData.currentLocalMinimumPrice;
    //       } else {
    //         // App is running, so no need to compare with previous day's local minima
    //         double lastTradedPriceCorrected = dynStock.lastTradedPrice;
    //         currentTickerData.currentLocalMinimumPrice = min(
    //             min(currentTickerData.currentLocalMinimumPrice,
    //                 lastTradedPriceCorrected),
    //             currentTickerData.price.currentPrice ?? double.infinity);
    //         currentTickerData.currentLocalMaximumPrice =
    //             currentTickerData.currentLocalMinimumPrice;
    //       }
    //     }

    //     store.dispatch(GetAllTickerDataSuccessAction(allTickerData: map));
    //     lastTransactionTime = lastTransactionTime.subtract(Duration(
    //         hours: lastTransactionTime.hour,
    //         minutes: lastTransactionTime.minute,
    //         seconds: lastTransactionTime.second,
    //         milliseconds: lastTransactionTime.millisecond));
    //     DateTime secondNextDayOfLastTransactionTime =
    //         lastTransactionTime.add(Duration(days: 2));
    //     String formattedsecondNextDayOfLastTransactionTime =
    //         formatter.format(secondNextDayOfLastTransactionTime);
    //     lastTransactionTime =
    //         DateTime.parse(formattedsecondNextDayOfLastTransactionTime);

    //     if (!stockMarketClosed &&
    //         (store.state.transactionsCreateState.data[dynStock.stockCode] !=
    //             null) &&
    //         !(store.state.transactionsCreateState.data[dynStock.stockCode]!
    //             .creating) &&
    //         !(pauseTransactions[dynStock.stockCode] == true)) {
    //       if (!LastDispatchedOrderTime.data.containsKey(dynStock.stockCode)) {
    //         LastDispatchedOrderTime.data[dynStock.stockCode] = DateTime(2020);
    //       }
    //       DateTime lastDispatchedOrderTime =
    //           LastDispatchedOrderTime.data[dynStock.stockCode] as DateTime;
    //       DateTime now = DateTime.now();
    //       Duration difference = now.difference(lastDispatchedOrderTime);
    //       // SELL Logic
    //       if (dynStock.lastTransactionType == 'BUY' &&
    //           !(dynStock.stallTransactions)) {
    //         if ((now.compareTo(secondNextDayOfLastTransactionTime) >= 0 &&
    //                 dynStock.stockType == EStockType.BE.name) ||
    //             dynStock.stockType != EStockType.BE.name) {
    //           switch (dynStock.DSTPUnit) {
    //             case 'Price':
    //               if (((dynStock.lastTradedPrice -
    //                           currentTickerData.price.currentPrice!) <=
    //                       dynStock.HETolerance) &&
    //                   ((dynStock.lastTradedPrice -
    //                           currentTickerData.price.currentPrice!) >=
    //                       dynStock.LETolerance) &&
    //                   (difference.inMinutes >= 1)) {
    //                 orderPlaced = true;

    //                 orderType = 'SELL';
    //                 store.dispatch(CreateTransactionAction(
    //                     userId: appStore.state.userId,
    //                     instrumentToken: dynStock.instrumentToken,
    //                     dynStockId: dynStock.dynStockId,
    //                     stockCode: dynStock.stockCode,
    //                     stockOrderType: EStockOrderType.Market.name,
    //                     body: TransactionBody(
    //                       transactionId: '',
    //                       type: 'SELL',
    //                       noOfStocks: dynStock.stocksAvailableForTrade == 0
    //                           ? dynStock.noOfStocks
    //                           : dynStock.stocksAvailableForTrade,
    //                       stockCode: dynStock.stockCode,
    //                       stockPrice: 0,
    //                     )));
    //               } else if (currentTickerData.price.currentPrice != null &&
    //                   (currentTickerData.price.currentPrice! <=
    //                       currentTickerData.currentLocalMaximumPrice - dynStock.STPr) &&
    //                   (difference.inMinutes >= 1)) {
    //                 orderPlaced = true;

    //                 orderType = 'SELL';
    //                 store.dispatch(CreateTransactionAction(
    //                     userId: appStore.state.userId,
    //                     instrumentToken: dynStock.instrumentToken,
    //                     stockOrderType: EStockOrderType.Market.name,
    //                     dynStockId: dynStock.dynStockId,
    //                     stockCode: dynStock.stockCode,
    //                     body: TransactionBody(
    //                       transactionId: '',
    //                       type: 'SELL',
    //                       noOfStocks: dynStock.stocksAvailableForTrade == 0
    //                           ? dynStock.noOfStocks
    //                           : dynStock.stocksAvailableForTrade,
    //                       stockCode: dynStock.stockCode,
    //                       stockPrice: 0,
    //                     )));
    //               }
    //               break;
    //             case 'Percentage':
    //               if (((dynStock.lastTradedPrice -
    //                           currentTickerData.price.currentPrice!) <=
    //                       dynStock.HETolerance) &&
    //                   ((dynStock.lastTradedPrice -
    //                           currentTickerData.price.currentPrice!) >=
    //                       dynStock.LETolerance) &&
    //                   (difference.inMinutes >= 1)) {
    //                 orderPlaced = true;

    //                 orderType = 'SELL';
    //                 store.dispatch(CreateTransactionAction(
    //                     userId: appStore.state.userId,
    //                     instrumentToken: dynStock.instrumentToken,
    //                     dynStockId: dynStock.dynStockId,
    //                     stockCode: dynStock.stockCode,
    //                     stockOrderType: EStockOrderType.Market.name,
    //                     body: TransactionBody(
    //                       transactionId: '',
    //                       type: 'SELL',
    //                       noOfStocks: dynStock.stocksAvailableForTrade == 0
    //                           ? dynStock.noOfStocks
    //                           : dynStock.stocksAvailableForTrade,
    //                       stockCode: dynStock.stockCode,
    //                       stockPrice: 0,
    //                     )));
    //               } else if (currentTickerData.price.currentPrice != null &&
    //                   (currentTickerData.price.currentPrice! <=
    //                       double.parse(((currentTickerData.currentLocalMaximumPrice) *
    //                               (1 - (dynStock.STPe / 100)))
    //                           .toStringAsFixed(2))) &&
    //                   (difference.inMinutes >= 1)) {
    //                 orderPlaced = true;

    //                 orderType = 'SELL';
    //                 store.dispatch(CreateTransactionAction(
    //                     userId: appStore.state.userId,
    //                     instrumentToken: dynStock.instrumentToken,
    //                     stockOrderType: EStockOrderType.Market.name,
    //                     dynStockId: dynStock.dynStockId,
    //                     stockCode: dynStock.stockCode,
    //                     body: TransactionBody(
    //                       transactionId: '',
    //                       type: 'SELL',
    //                       noOfStocks: dynStock.stocksAvailableForTrade == 0
    //                           ? dynStock.noOfStocks
    //                           : dynStock.stocksAvailableForTrade,
    //                       stockCode: dynStock.stockCode,
    //                       stockPrice: 0,
    //                     )));
    //               }
    //               break;
    //           }
    //         }
    //       }
    //       // BUY Logic
    //       if (dynStock.lastTransactionType == 'SELL' &&
    //           !(dynStock.stallTransactions)) {
    //         switch (dynStock.DSTPUnit) {
    //           case 'Price':
    //             if (((currentTickerData.price.currentPrice! -
    //                         dynStock.lastTradedPrice) <=
    //                     dynStock.HETolerance) &&
    //                 ((currentTickerData.price.currentPrice! -
    //                         dynStock.lastTradedPrice) >=
    //                     dynStock.LETolerance) &&
    //                 (difference.inMinutes >= 1)) {
    //               orderPlaced = true;

    //               orderType = 'BUY';
    //               store.dispatch(CreateTransactionAction(
    //                   userId: appStore.state.userId,
    //                   instrumentToken: dynStock.instrumentToken,
    //                   dynStockId: dynStock.dynStockId,
    //                   stockCode: dynStock.stockCode,
    //                   stockOrderType: EStockOrderType.Market.name,
    //                   body: TransactionBody(
    //                     transactionId: '',
    //                     type: 'BUY',
    //                     noOfStocks: (dynStock.noOfStocks -
    //                         dynStock.stocksAvailableForTrade),
    //                     stockCode: dynStock.stockCode,
    //                     stockPrice: 0,
    //                   )));
    //             } else if (currentTickerData.price.currentPrice != null &&
    //                 (currentTickerData.price.currentPrice! >=
    //                     currentTickerData.currentLocalMinimumPrice + dynStock.BTPr) &&
    //                 (difference.inMinutes >= 1)) {
    //               orderPlaced = true;

    //               orderType = 'BUY';
    //               store.dispatch(CreateTransactionAction(
    //                   userId: appStore.state.userId,
    //                   instrumentToken: dynStock.instrumentToken,
    //                   stockOrderType: EStockOrderType.Market.name,
    //                   dynStockId: dynStock.dynStockId,
    //                   stockCode: dynStock.stockCode,
    //                   body: TransactionBody(
    //                     transactionId: '',
    //                     type: 'BUY',
    //                     noOfStocks: (dynStock.noOfStocks -
    //                         dynStock.stocksAvailableForTrade),
    //                     stockCode: dynStock.stockCode,
    //                     stockPrice: 0,
    //                   )));
    //             }
    //             break;
    //           case 'Percentage':
    //             if (((currentTickerData.price.currentPrice! -
    //                         dynStock.lastTradedPrice) <=
    //                     dynStock.HETolerance) &&
    //                 ((currentTickerData.price.currentPrice! -
    //                         dynStock.lastTradedPrice) >=
    //                     dynStock.LETolerance) &&
    //                 (difference.inMinutes >= 1)) {
    //               orderPlaced = true;

    //               orderType = 'BUY';
    //               store.dispatch(CreateTransactionAction(
    //                   userId: appStore.state.userId,
    //                   instrumentToken: dynStock.instrumentToken,
    //                   dynStockId: dynStock.dynStockId,
    //                   stockOrderType: EStockOrderType.Market.name,
    //                   stockCode: dynStock.stockCode,
    //                   body: TransactionBody(
    //                     transactionId: '',
    //                     type: 'BUY',
    //                     noOfStocks: (dynStock.noOfStocks -
    //                         dynStock.stocksAvailableForTrade),
    //                     stockCode: dynStock.stockCode,
    //                     stockPrice: 0,
    //                   )));
    //             } else if (currentTickerData.price.currentPrice != null &&
    //                 (currentTickerData.price.currentPrice! >=
    //                     double.parse(((currentTickerData.currentLocalMinimumPrice) *
    //                             (1 + (dynStock.BTPe / 100)))
    //                         .toStringAsFixed(2))) &&
    //                 (difference.inMinutes >= 1)) {
    //               orderPlaced = true;

    //               orderType = 'BUY';
    //               store.dispatch(CreateTransactionAction(
    //                   userId: appStore.state.userId,
    //                   instrumentToken: dynStock.instrumentToken,
    //                   dynStockId: dynStock.dynStockId,
    //                   stockOrderType: EStockOrderType.Market.name,
    //                   stockCode: dynStock.stockCode,
    //                   body: TransactionBody(
    //                     transactionId: '',
    //                     type: 'BUY',
    //                     noOfStocks: (dynStock.noOfStocks -
    //                         dynStock.stocksAvailableForTrade),
    //                     stockCode: dynStock.stockCode,
    //                     stockPrice: 0,
    //                   )));
    //             }
    //             break;
    //         }
    //       }
    //     }
    //   }).catchError((error) {
    //     print(error);
    //     store.dispatch(GetAllTickerDataFailAction(error: error));
    //     String emailBodyLine1 = '$error';
    //     GmailErrorMessageService.sendEmail('Error in ticker data middleware',
    //             '<h2>Error in ticker data middleware</h2><br/><p>${emailBodyLine1}</p>')
    //         .then((value) {})
    //         .catchError((error) {
    //       print(error);
    //     });
    //     EmailJSService()
    //         .sendEmail(Email(
    //             username: 'Myself',
    //             subject: 'Error in ticker data middleware',
    //             title: 'Error in ticker data middleware',
    //             subtitle: 'Error in ticker data middleware ${emailBodyLine1}',
    //             body: emailBodyLine1))
    //         .then((value) {})
    //         .catchError((error) {
    //       print(error);
    //     });
    //   });
    // });

  }
  next(action);
}
