import 'dart:async';

import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:dynstocks/services/transactions.service.dart';
import 'package:redux/redux.dart';

void transactionsMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetAllTransactionsAction) {
    TransactionsService()
        .getTransactionsForDate(action.userId,
            date: action.date,
            limit: action.limit,
            offset: action.offset,
            sortCriterion: action.sortCriterion,
            sortDirection: action.sortDirection,
            dynStockId: action.dynStockId,
            filterCriterionStocks: action.filterCriterionStocks,
            filterCriterionDay: action.filterCriterionDay)
        .then((response) {
      store.dispatch(GetAllTransactionsSuccessAction(data: response));
    }).catchError((error) {
      store.dispatch(GetAllTransactionsFailAction(error: error));
    });
  }
  if (action is CreateTransactionAction) {
    if (action.placeKotakAPIStockOrder) {
      if (!(store
          .state.transactionsCreateState.data[action.stockCode]!.creating)) {
        KotakStockAPIService()
            .placeOrder(
                action.userId,
                store.state.accessCode,
                KotakStockAPIPlaceOrderBody(
                    orderType: 'N',
                    instrumentToken: action.instrumentToken,
                    transactionType: action.body.type,
                    quantity: action.body.noOfStocks,
                    price: action.stockOrderType == EStockOrderType.Limit.name
                        ? action.body.stockPrice
                        : 0.0))
            .then((order) {
          bool orderPlacedInNSE = order!.success!.nse != null ? true : false;
          ///////
          Future.delayed(Duration(milliseconds: 200), () {
            KotakStockAPIService()
                .getOrderReport(
                    action.userId,
                    store.state.accessCode,
                    (orderPlacedInNSE
                        ? order.success!.nse!.orderId
                        : order.success!.bse!.orderId),
                    action.instrumentToken)
                .then((position) {
              OrderReportsSuccess tradedStock = position!.success.firstWhere(
                  (element) =>
                      element.orderId ==
                      (orderPlacedInNSE
                          ? order.success!.nse!.orderId
                          : order.success!.bse!.orderId));
              int orderId = orderPlacedInNSE
                  ? order.success!.nse!.orderId
                  : order.success!.bse!.orderId;
              if (tradedStock.statusInfo == EStockTradeStatusInfo.Traded.name) {
                TransactionsService()
                    .createTransaction(
                        action.userId,
                        action.dynStockId,
                        TransactionBody(
                            transactionId: orderPlacedInNSE
                                ? order.success!.nse!.orderId.toString()
                                : order.success!.bse!.orderId.toString(),
                            type: action.body.type,
                            noOfStocks: action.body.noOfStocks,
                            stockCode: action.body.stockCode,
                            stockPrice: tradedStock.price))
                    .then((response) {
                  store.dispatch(CreateTransactionSuccessAction(
                      stockCode: action.stockCode));
                  store.state.allTickerData.data[action.stockCode]!
                      .currentLocalMaximumPrice = tradedStock.price;
                  store.state.allTickerData.data[action.stockCode]!
                      .currentLocalMinimumPrice = tradedStock.price;
                  store.dispatch(GetAllTickerDataSuccessAction(
                      allTickerData: store.state.allTickerData.data));
                  DateTime transactionTime =
                      DateTime.fromMillisecondsSinceEpoch(
                          response.transactionTime.date);
                  String emailBodyLine1 =
                      'Transaction Type: ${response.type}, Transaction Price: ${response.stockPrice}, Number of Stocks: ${response.noOfStocks}';
                  String emailBodyLine2 =
                      'Transaction Time: ${transactionTime.hour}:${transactionTime.minute}:${transactionTime.second} ${transactionTime.day}/${transactionTime.month}/${transactionTime.year}';
                  String emailBodyLine3 = 'Total Amount: ${response.amount}';
                  store.dispatch(GetAllDynStocksAction(userId: action.userId));
                  // EmailJSService()
                  //     .sendEmail(Email(
                  //         username: 'Myself',
                  //         subject: 'Transaction Made',
                  //         title: 'Transaction Made for ${action.body.stockCode}',
                  //         subtitle:
                  //             'Transaction has been made for ${action.body.stockCode} with the following params',
                  //         body:
                  //             '${emailBodyLine1} ${emailBodyLine2} ${emailBodyLine3}'))
                  //     .then((value) {
                  // }).catchError((error) {
                  //   placingOrder = false;
                  //   store.dispatch(CreateTransactionFailAction(error: error));
                  // });
                }).catchError((error) {
                  store.dispatch(CreateTransactionFailAction(
                      stockCode: action.stockCode, error: error));
                });
              } else {
                Timer.periodic(Duration(seconds: 10), (timer) {
                  KotakStockAPIService()
                      .getOrderReport(
                          action.userId,
                          store.state.accessCode,
                          (orderPlacedInNSE
                              ? order.success!.nse!.orderId
                              : order.success!.bse!.orderId),
                          action.instrumentToken)
                      .then((position) {
                    OrderReportsSuccess tradedStock = position!.success
                        .firstWhere((element) =>
                            element.orderId ==
                            (orderPlacedInNSE
                                ? order.success!.nse!.orderId
                                : order.success!.bse!.orderId));
                    int orderId = orderPlacedInNSE
                        ? order.success!.nse!.orderId
                        : order.success!.bse!.orderId;
                    if (tradedStock.statusInfo ==
                        EStockTradeStatusInfo.Traded.name) {
                      timer.cancel();
                      TransactionsService()
                          .createTransaction(
                              action.userId,
                              action.dynStockId,
                              TransactionBody(
                                  transactionId: orderPlacedInNSE
                                      ? order.success!.nse!.orderId.toString()
                                      : order.success!.bse!.orderId.toString(),
                                  type: action.body.type,
                                  noOfStocks: action.body.noOfStocks,
                                  stockCode: action.body.stockCode,
                                  stockPrice: tradedStock.price))
                          .then((response) {
                        store.dispatch(CreateTransactionSuccessAction(
                          stockCode: action.stockCode,
                        ));
                        store.state.allTickerData.data[action.stockCode]!
                            .currentLocalMaximumPrice = tradedStock.price;
                        store.state.allTickerData.data[action.stockCode]!
                            .currentLocalMinimumPrice = tradedStock.price;
                        store.dispatch(GetAllTickerDataSuccessAction(
                            allTickerData: store.state.allTickerData.data));
                        DateTime transactionTime =
                            DateTime.fromMillisecondsSinceEpoch(
                                response.transactionTime.date);
                        String emailBodyLine1 =
                            'Transaction Type: ${response.type}, Transaction Price: ${response.stockPrice}, Number of Stocks: ${response.noOfStocks}';
                        String emailBodyLine2 =
                            'Transaction Time: ${transactionTime.hour}:${transactionTime.minute}:${transactionTime.second} ${transactionTime.day}/${transactionTime.month}/${transactionTime.year}';
                        String emailBodyLine3 =
                            'Total Amount: ${response.amount}';
                        store.dispatch(
                            GetAllDynStocksAction(userId: action.userId));
                        // EmailJSService()
                        //     .sendEmail(Email(
                        //         username: 'Myself',
                        //         subject: 'Transaction Made',
                        //         title: 'Transaction Made for ${action.body.stockCode}',
                        //         subtitle:
                        //             'Transaction has been made for ${action.body.stockCode} with the following params',
                        //         body:
                        //             '${emailBodyLine1} ${emailBodyLine2} ${emailBodyLine3}'))
                        //     .then((value) {
                        // }).catchError((error) {
                        //   placingOrder = false;
                        //   store.dispatch(CreateTransactionFailAction(error: error));
                        // });
                      }).catchError((error) {
                        store.dispatch(CreateTransactionFailAction(
                            stockCode: action.stockCode, error: error));
                      });
                    }
                  }).catchError((error) {
                    store.dispatch(CreateTransactionFailAction(
                        stockCode: action.stockCode, error: error));
                  });
                });
              }
            }).catchError((error) {
              store.dispatch(CreateTransactionFailAction(
                  stockCode: action.stockCode, error: error));
            });
          });

          ///////
        }).catchError((error) {
          store.dispatch(CreateTransactionFailAction(
              stockCode: action.stockCode, error: error));
        });
      }
    } else {
      TransactionsService()
          .createTransaction(
              action.userId,
              action.dynStockId,
              TransactionBody(
                  transactionId: action.body.transactionId,
                  type: action.body.type,
                  noOfStocks: action.body.noOfStocks,
                  stockCode: action.body.stockCode,
                  stockPrice: action.body.stockPrice))
          .then((response) {
        store.dispatch(
            CreateTransactionSuccessAction(stockCode: action.stockCode));
        store.state.allTickerData.data[action.stockCode]!
            .currentLocalMaximumPrice = action.body.stockPrice;
        store.state.allTickerData.data[action.stockCode]!
            .currentLocalMinimumPrice = action.body.stockPrice;
        store.dispatch(GetAllTickerDataSuccessAction(
            allTickerData: store.state.allTickerData.data));
        DateTime transactionTime =
            DateTime.fromMillisecondsSinceEpoch(response.transactionTime.date);
        String emailBodyLine1 =
            'Transaction Type: ${response.type}, Transaction Price: ${response.stockPrice}, Number of Stocks: ${response.noOfStocks}';
        String emailBodyLine2 =
            'Transaction Time: ${transactionTime.hour}:${transactionTime.minute}:${transactionTime.second} ${transactionTime.day}/${transactionTime.month}/${transactionTime.year}';
        String emailBodyLine3 = 'Total Amount: ${response.amount}';
        store.dispatch(GetAllDynStocksAction(userId: action.userId));
        // EmailJSService()
        //     .sendEmail(Email(
        //         username: 'Myself',
        //         subject: 'Transaction Made',
        //         title: 'Transaction Made for ${action.body.stockCode}',
        //         subtitle:
        //             'Transaction has been made for ${action.body.stockCode} with the following params',
        //         body:
        //             '${emailBodyLine1} ${emailBodyLine2} ${emailBodyLine3}'))
        //     .then((value) {
        // }).catchError((error) {
        //   placingOrder = false;
        //   store.dispatch(CreateTransactionFailAction(error: error));
        // });
      }).catchError((error) {
        store.dispatch(CreateTransactionFailAction(
            stockCode: action.stockCode, error: error));
      });
    }
  }
  next(action);
}
