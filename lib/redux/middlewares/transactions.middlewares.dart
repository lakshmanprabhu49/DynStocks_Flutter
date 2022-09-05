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
      String emailBodyLine1 = '$error';
      EmailJSService()
          .sendEmail(Email(
              username: 'Myself',
              subject:
                  'Error while getting all transactions for DynStock ${action.dynStockId}',
              title:
                  'Error while getting all transactions for DynStock ${action.dynStockId}',
              subtitle:
                  'Error while getting all transactions for DynStock ${action.dynStockId}',
              body: emailBodyLine1))
          .then((value) {})
          .catchError((error) {});
      store.dispatch(GetAllTransactionsFailAction(error: error));
    });
  }
  if (action is CreateTransactionAction) {
    if (action.placeKotakAPIStockOrder) {
      if (!action.forcedTransaction) {
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
                if (tradedStock.statusInfo ==
                    EStockTradeStatusInfo.Traded.name) {
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
                    store
                        .dispatch(GetAllDynStocksAction(userId: action.userId));
                  }).catchError((error) {
                    String emailBodyLine1 = '$error';
                    EmailJSService()
                        .sendEmail(Email(
                            username: 'Myself',
                            subject:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            title:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            subtitle:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            body: emailBodyLine1))
                        .then((value) {})
                        .catchError((error) {});
                    store.dispatch(CreateTransactionFailAction(
                        stockCode: action.stockCode, error: error));
                  });
                } else {
                  Timer.periodic(Duration(seconds: 3), (timer) {
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
                                        : order.success!.bse!.orderId
                                            .toString(),
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
                          store.dispatch(
                              GetAllDynStocksAction(userId: action.userId));
                        }).catchError((error) {
                          String emailBodyLine1 = '$error';
                          EmailJSService()
                              .sendEmail(Email(
                                  username: 'Myself',
                                  subject:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  title:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  subtitle:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  body: emailBodyLine1))
                              .then((value) {})
                              .catchError((error) {});
                          store.dispatch(CreateTransactionFailAction(
                              stockCode: action.stockCode, error: error));
                        });
                      }
                    }).catchError((error) {
                      String emailBodyLine1 = '$error';
                      EmailJSService()
                          .sendEmail(Email(
                              username: 'Myself',
                              subject:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              title:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              subtitle:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              body: emailBodyLine1))
                          .then((value) {})
                          .catchError((error) {});
                      store.dispatch(CreateTransactionFailAction(
                          stockCode: action.stockCode, error: error));
                    });
                  });
                }
              }).catchError((error) {
                String emailBodyLine1 = '$error';
                EmailJSService()
                    .sendEmail(Email(
                        username: 'Myself',
                        subject:
                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                        title:
                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                        subtitle:
                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                        body: emailBodyLine1))
                    .then((value) {})
                    .catchError((error) {});
                store.dispatch(CreateTransactionFailAction(
                    stockCode: action.stockCode, error: error));
              });
            });

            ///////
          }).catchError((error) {
            String emailBodyLine1 = '$error';
            EmailJSService()
                .sendEmail(Email(
                    username: 'Myself',
                    subject:
                        'Error while creating transaction for DynStock ${action.body.stockCode}',
                    title:
                        'Error while creating transaction for DynStock ${action.body.stockCode}',
                    subtitle:
                        'Error while creating transaction for DynStock ${action.body.stockCode}',
                    body: emailBodyLine1))
                .then((value) {})
                .catchError((error) {});
            store.dispatch(CreateTransactionFailAction(
                stockCode: action.stockCode, error: error));
          });
        }
      } else {
        KotakStockAPIService()
            .getAllOrderReport(
                action.userId, store.state.accessCode, action.instrumentToken)
            .then((orderReports) {
          bool thereAreNoIncompleteOrders = true;
          for (var orderReport in orderReports!.success) {
            if (action.body.type == ETransactionType.BUY.name) {
              // Force BUY is initiated. If there is any open transaction for BUY, cancel it
              // If there is a partial transaction for BUY,Modify it such that it becomes a full transaction, change noOfStocks to the traded stocks
              // For the remaining stocks that are not bought in above, BUY it at the market price
              if (orderReport.statusInfo == EStockTradeStatusInfo.Open.name) {
                KotakStockAPIService()
                    .cancelOrder(action.userId, store.state.accessCode,
                        orderReport.orderId.toString())
                    .then((cancelledOrder) {
                  store.dispatch(CreateTransactionSuccessAction(
                      stockCode: action.stockCode));
                  store.dispatch(GetAllTickerDataSuccessAction(
                      allTickerData: store.state.allTickerData.data));
                  store.dispatch(GetAllDynStocksAction(userId: action.userId));
                }).catchError((error) {
                  String emailBodyLine1 = '$error';
                  EmailJSService()
                      .sendEmail(Email(
                          username: 'Myself',
                          subject:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          title:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          subtitle:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          body: emailBodyLine1))
                      .then((value) {})
                      .catchError((error) {});
                  store.dispatch(CreateTransactionFailAction(
                      stockCode: action.stockCode, error: error));
                });
                thereAreNoIncompleteOrders = false;
              } else if (orderReport.statusInfo ==
                  EStockTradeStatusInfo.Partially_Traded.name) {
                // Modify the order first such that , partially traded transaction becomes Fully Traded transaction
                thereAreNoIncompleteOrders = false;
                int quantityBoughtAlready =
                    orderReport.orderQuantity - orderReport.pendingQuantity;
                KotakStockAPIService()
                    .modifyOrder(
                        action.userId,
                        store.state.accessCode,
                        orderReport.orderId.toString(),
                        KotakStockAPIPlaceOrderBody(
                            orderType: 'N',
                            instrumentToken: action.instrumentToken,
                            transactionType: ETransactionType.BUY.name,
                            quantity: quantityBoughtAlready))
                    .then((modifiedOrder) {
                  bool orderPlacedInNSE =
                      modifiedOrder!.success!.nse != null ? true : false;
                  TransactionsService()
                      .createTransaction(
                          action.userId,
                          action.dynStockId,
                          TransactionBody(
                              transactionId: orderPlacedInNSE
                                  ? modifiedOrder.success!.nse!.orderId
                                      .toString()
                                  : modifiedOrder.success!.bse!.orderId
                                      .toString(),
                              type: action.body.type,
                              noOfStocks: action.body.noOfStocks,
                              stockCode: action.body.stockCode,
                              stockPrice: orderReport.price))
                      .then((response) {
                    // Then place the BUY order to BUY the remaining quantity at the market price
                    KotakStockAPIService()
                        .placeOrder(
                            action.userId,
                            store.state.accessCode,
                            KotakStockAPIPlaceOrderBody(
                                orderType: 'N',
                                instrumentToken: action.instrumentToken,
                                transactionType: ETransactionType.BUY.name,
                                quantity: orderReport.pendingQuantity))
                        .then((newOrder) {
                      bool orderPlacedInNSE =
                          newOrder!.success!.nse != null ? true : false;
                      Future.delayed(Duration(milliseconds: 200), () {
                        KotakStockAPIService()
                            .getOrderReport(
                                action.userId,
                                store.state.accessCode,
                                (orderPlacedInNSE
                                    ? newOrder.success!.nse!.orderId
                                    : newOrder.success!.bse!.orderId),
                                action.instrumentToken)
                            .then((position) {
                          OrderReportsSuccess tradedStock = position!.success
                              .firstWhere((element) =>
                                  element.orderId ==
                                  (orderPlacedInNSE
                                      ? newOrder.success!.nse!.orderId
                                      : newOrder.success!.bse!.orderId));
                          int orderId = orderPlacedInNSE
                              ? newOrder.success!.nse!.orderId
                              : newOrder.success!.bse!.orderId;
                          if (tradedStock.statusInfo ==
                              EStockTradeStatusInfo.Traded.name) {
                            TransactionsService()
                                .createTransaction(
                                    action.userId,
                                    action.dynStockId,
                                    TransactionBody(
                                        transactionId: orderPlacedInNSE
                                            ? newOrder.success!.nse!.orderId
                                                .toString()
                                            : newOrder.success!.bse!.orderId
                                                .toString(),
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
                                  allTickerData:
                                      store.state.allTickerData.data));
                            }).catchError((error) {
                              String emailBodyLine1 = '$error';
                              EmailJSService()
                                  .sendEmail(Email(
                                      username: 'Myself',
                                      subject:
                                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                                      title:
                                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                                      subtitle:
                                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                                      body: emailBodyLine1))
                                  .then((value) {})
                                  .catchError((error) {});
                              store.dispatch(CreateTransactionFailAction(
                                  stockCode: action.stockCode, error: error));
                            });
                          } else {
                            Timer.periodic(Duration(seconds: 3), (timer) {
                              KotakStockAPIService()
                                  .getOrderReport(
                                      action.userId,
                                      store.state.accessCode,
                                      (orderPlacedInNSE
                                          ? newOrder.success!.nse!.orderId
                                          : newOrder.success!.bse!.orderId),
                                      action.instrumentToken)
                                  .then((position) {
                                OrderReportsSuccess tradedStock =
                                    position!.success.firstWhere((element) =>
                                        element.orderId ==
                                        (orderPlacedInNSE
                                            ? newOrder.success!.nse!.orderId
                                            : newOrder.success!.bse!.orderId));
                                int orderId = orderPlacedInNSE
                                    ? newOrder.success!.nse!.orderId
                                    : newOrder.success!.bse!.orderId;
                                if (tradedStock.statusInfo ==
                                    EStockTradeStatusInfo.Traded.name) {
                                  timer.cancel();
                                  TransactionsService()
                                      .createTransaction(
                                          action.userId,
                                          action.dynStockId,
                                          TransactionBody(
                                              transactionId: orderPlacedInNSE
                                                  ? newOrder
                                                      .success!.nse!.orderId
                                                      .toString()
                                                  : newOrder
                                                      .success!.bse!.orderId
                                                      .toString(),
                                              type: action.body.type,
                                              noOfStocks:
                                                  action.body.noOfStocks,
                                              stockCode: action.body.stockCode,
                                              stockPrice: tradedStock.price))
                                      .then((response) {
                                    store.dispatch(
                                        CreateTransactionSuccessAction(
                                      stockCode: action.stockCode,
                                    ));
                                    store
                                            .state
                                            .allTickerData
                                            .data[action.stockCode]!
                                            .currentLocalMaximumPrice =
                                        tradedStock.price;
                                    store
                                            .state
                                            .allTickerData
                                            .data[action.stockCode]!
                                            .currentLocalMinimumPrice =
                                        tradedStock.price;
                                    store.dispatch(
                                        GetAllTickerDataSuccessAction(
                                            allTickerData: store
                                                .state.allTickerData.data));
                                    store.dispatch(GetAllDynStocksAction(
                                        userId: action.userId));
                                  }).catchError((error) {
                                    String emailBodyLine1 =
                                        '${error['message']}';
                                    EmailJSService()
                                        .sendEmail(Email(
                                            username: 'Myself',
                                            subject:
                                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                                            title:
                                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                                            subtitle:
                                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                                            body: emailBodyLine1))
                                        .then((value) {})
                                        .catchError((error) {});
                                    store.dispatch(CreateTransactionFailAction(
                                        stockCode: action.stockCode,
                                        error: error));
                                  });
                                }
                              }).catchError((error) {
                                String emailBodyLine1 = '$error';
                                EmailJSService()
                                    .sendEmail(Email(
                                        username: 'Myself',
                                        subject:
                                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                                        title:
                                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                                        subtitle:
                                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                                        body: emailBodyLine1))
                                    .then((value) {})
                                    .catchError((error) {});
                                store.dispatch(CreateTransactionFailAction(
                                    stockCode: action.stockCode, error: error));
                              });
                            });
                          }
                        }).catchError((error) {
                          String emailBodyLine1 = '$error';
                          EmailJSService()
                              .sendEmail(Email(
                                  username: 'Myself',
                                  subject:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  title:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  subtitle:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  body: emailBodyLine1))
                              .then((value) {})
                              .catchError((error) {});
                          store.dispatch(CreateTransactionFailAction(
                              stockCode: action.stockCode, error: error));
                        });
                      });
                    }).catchError((error) {
                      String emailBodyLine1 = '$error';
                      EmailJSService()
                          .sendEmail(Email(
                              username: 'Myself',
                              subject:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              title:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              subtitle:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              body: emailBodyLine1))
                          .then((value) {})
                          .catchError((error) {});
                      store.dispatch(CreateTransactionFailAction(
                          stockCode: action.stockCode, error: error));
                    });
                  }).catchError((error) {
                    String emailBodyLine1 = '$error';
                    EmailJSService()
                        .sendEmail(Email(
                            username: 'Myself',
                            subject:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            title:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            subtitle:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            body: emailBodyLine1))
                        .then((value) {})
                        .catchError((error) {});
                    store.dispatch(CreateTransactionFailAction(
                        stockCode: action.stockCode, error: error));
                  });
                }).catchError((error) {
                  String emailBodyLine1 = '$error';
                  EmailJSService()
                      .sendEmail(Email(
                          username: 'Myself',
                          subject:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          title:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          subtitle:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          body: emailBodyLine1))
                      .then((value) {})
                      .catchError((error) {});
                  store.dispatch(CreateTransactionFailAction(
                      stockCode: action.stockCode, error: error));
                });
              }
            } else if (action.body.type == ETransactionType.SELL.name) {
              // Force SELL is initiated. If there is any open transaction for SELL, cancel it
              // If there is a partial transaction for BUY,Modify it such that it becomes a full transaction, change noOfStocks to the traded stocks
              // For the remaining stocks that are not bought in above, BUY it at the market price
              if (orderReport.statusInfo == EStockTradeStatusInfo.Open.name) {
                thereAreNoIncompleteOrders = false;
                KotakStockAPIService()
                    .cancelOrder(action.userId, store.state.accessCode,
                        orderReport.orderId.toString())
                    .then((cancelledOrder) {
                  store.dispatch(CreateTransactionSuccessAction(
                      stockCode: action.stockCode));
                  store.dispatch(GetAllTickerDataSuccessAction(
                      allTickerData: store.state.allTickerData.data));
                  store.dispatch(GetAllDynStocksAction(userId: action.userId));
                }).catchError((error) {
                  String emailBodyLine1 = '$error';
                  EmailJSService()
                      .sendEmail(Email(
                          username: 'Myself',
                          subject:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          title:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          subtitle:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          body: emailBodyLine1))
                      .then((value) {})
                      .catchError((error) {});
                  store.dispatch(CreateTransactionFailAction(
                      stockCode: action.stockCode, error: error));
                });
              } else if (orderReport.statusInfo ==
                  EStockTradeStatusInfo.Partially_Traded.name) {
                // Modify the order first such that , partially traded transaction becomes Fully Traded transaction
                thereAreNoIncompleteOrders = false;
                int quantityBoughtSold =
                    orderReport.orderQuantity - orderReport.pendingQuantity;
                KotakStockAPIService()
                    .modifyOrder(
                        action.userId,
                        store.state.accessCode,
                        orderReport.orderId.toString(),
                        KotakStockAPIPlaceOrderBody(
                            orderType: 'N',
                            instrumentToken: action.instrumentToken,
                            transactionType: ETransactionType.BUY.name,
                            quantity: quantityBoughtSold))
                    .then((modifiedOrder) {
                  bool orderPlacedInNSE =
                      modifiedOrder!.success!.nse != null ? true : false;
                  TransactionsService()
                      .createTransaction(
                          action.userId,
                          action.dynStockId,
                          TransactionBody(
                              transactionId: orderPlacedInNSE
                                  ? modifiedOrder.success!.nse!.orderId
                                      .toString()
                                  : modifiedOrder.success!.bse!.orderId
                                      .toString(),
                              type: action.body.type,
                              noOfStocks: action.body.noOfStocks,
                              stockCode: action.body.stockCode,
                              stockPrice: orderReport.price))
                      .then((response) {
                    KotakStockAPIService()
                        .placeOrder(
                            action.userId,
                            store.state.accessCode,
                            KotakStockAPIPlaceOrderBody(
                                orderType: 'N',
                                instrumentToken: action.instrumentToken,
                                transactionType: ETransactionType.SELL.name,
                                quantity: orderReport.pendingQuantity))
                        .then((newOrder) {
                      bool orderPlacedInNSE =
                          newOrder!.success!.nse != null ? true : false;
                      Future.delayed(Duration(milliseconds: 200), () {
                        KotakStockAPIService()
                            .getOrderReport(
                                action.userId,
                                store.state.accessCode,
                                (orderPlacedInNSE
                                    ? newOrder.success!.nse!.orderId
                                    : newOrder.success!.bse!.orderId),
                                action.instrumentToken)
                            .then((position) {
                          OrderReportsSuccess tradedStock = position!.success
                              .firstWhere((element) =>
                                  element.orderId ==
                                  (orderPlacedInNSE
                                      ? newOrder.success!.nse!.orderId
                                      : newOrder.success!.bse!.orderId));
                          int orderId = orderPlacedInNSE
                              ? newOrder.success!.nse!.orderId
                              : newOrder.success!.bse!.orderId;
                          if (tradedStock.statusInfo ==
                              EStockTradeStatusInfo.Traded.name) {
                            TransactionsService()
                                .createTransaction(
                                    action.userId,
                                    action.dynStockId,
                                    TransactionBody(
                                        transactionId: orderPlacedInNSE
                                            ? newOrder.success!.nse!.orderId
                                                .toString()
                                            : newOrder.success!.bse!.orderId
                                                .toString(),
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
                                  allTickerData:
                                      store.state.allTickerData.data));
                              store.dispatch(
                                  GetAllDynStocksAction(userId: action.userId));
                            }).catchError((error) {
                              String emailBodyLine1 = '$error';
                              EmailJSService()
                                  .sendEmail(Email(
                                      username: 'Myself',
                                      subject:
                                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                                      title:
                                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                                      subtitle:
                                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                                      body: emailBodyLine1))
                                  .then((value) {})
                                  .catchError((error) {});
                              store.dispatch(CreateTransactionFailAction(
                                  stockCode: action.stockCode, error: error));
                            });
                          } else {
                            Timer.periodic(Duration(seconds: 3), (timer) {
                              KotakStockAPIService()
                                  .getOrderReport(
                                      action.userId,
                                      store.state.accessCode,
                                      (orderPlacedInNSE
                                          ? newOrder.success!.nse!.orderId
                                          : newOrder.success!.bse!.orderId),
                                      action.instrumentToken)
                                  .then((position) {
                                OrderReportsSuccess tradedStock =
                                    position!.success.firstWhere((element) =>
                                        element.orderId ==
                                        (orderPlacedInNSE
                                            ? newOrder.success!.nse!.orderId
                                            : newOrder.success!.bse!.orderId));
                                int orderId = orderPlacedInNSE
                                    ? newOrder.success!.nse!.orderId
                                    : newOrder.success!.bse!.orderId;
                                if (tradedStock.statusInfo ==
                                    EStockTradeStatusInfo.Traded.name) {
                                  timer.cancel();
                                  TransactionsService()
                                      .createTransaction(
                                          action.userId,
                                          action.dynStockId,
                                          TransactionBody(
                                              transactionId: orderPlacedInNSE
                                                  ? newOrder
                                                      .success!.nse!.orderId
                                                      .toString()
                                                  : newOrder
                                                      .success!.bse!.orderId
                                                      .toString(),
                                              type: action.body.type,
                                              noOfStocks:
                                                  action.body.noOfStocks,
                                              stockCode: action.body.stockCode,
                                              stockPrice: tradedStock.price))
                                      .then((response) {
                                    store.dispatch(
                                        CreateTransactionSuccessAction(
                                      stockCode: action.stockCode,
                                    ));
                                    store
                                            .state
                                            .allTickerData
                                            .data[action.stockCode]!
                                            .currentLocalMaximumPrice =
                                        tradedStock.price;
                                    store
                                            .state
                                            .allTickerData
                                            .data[action.stockCode]!
                                            .currentLocalMinimumPrice =
                                        tradedStock.price;
                                    store.dispatch(
                                        GetAllTickerDataSuccessAction(
                                            allTickerData: store
                                                .state.allTickerData.data));

                                    store.dispatch(GetAllDynStocksAction(
                                        userId: action.userId));
                                  }).catchError((error) {
                                    String emailBodyLine1 =
                                        '${error['message']}';
                                    EmailJSService()
                                        .sendEmail(Email(
                                            username: 'Myself',
                                            subject:
                                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                                            title:
                                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                                            subtitle:
                                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                                            body: emailBodyLine1))
                                        .then((value) {})
                                        .catchError((error) {});
                                    store.dispatch(CreateTransactionFailAction(
                                        stockCode: action.stockCode,
                                        error: error));
                                  });
                                }
                              }).catchError((error) {
                                String emailBodyLine1 = '$error';
                                EmailJSService()
                                    .sendEmail(Email(
                                        username: 'Myself',
                                        subject:
                                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                                        title:
                                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                                        subtitle:
                                            'Error while creating transaction for DynStock ${action.body.stockCode}',
                                        body: emailBodyLine1))
                                    .then((value) {})
                                    .catchError((error) {});
                                store.dispatch(CreateTransactionFailAction(
                                    stockCode: action.stockCode, error: error));
                              });
                            });
                          }
                        }).catchError((error) {
                          String emailBodyLine1 = '$error';
                          EmailJSService()
                              .sendEmail(Email(
                                  username: 'Myself',
                                  subject:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  title:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  subtitle:
                                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                                  body: emailBodyLine1))
                              .then((value) {})
                              .catchError((error) {});
                          store.dispatch(CreateTransactionFailAction(
                              stockCode: action.stockCode, error: error));
                        });
                      });
                    }).catchError((error) {
                      String emailBodyLine1 = '$error';
                      EmailJSService()
                          .sendEmail(Email(
                              username: 'Myself',
                              subject:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              title:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              subtitle:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              body: emailBodyLine1))
                          .then((value) {})
                          .catchError((error) {});
                      store.dispatch(CreateTransactionFailAction(
                          stockCode: action.stockCode, error: error));
                    });
                  }).catchError((error) {
                    String emailBodyLine1 = '$error';
                    EmailJSService()
                        .sendEmail(Email(
                            username: 'Myself',
                            subject:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            title:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            subtitle:
                                'Error while creating transaction for DynStock ${action.body.stockCode}',
                            body: emailBodyLine1))
                        .then((value) {})
                        .catchError((error) {});
                    store.dispatch(CreateTransactionFailAction(
                        stockCode: action.stockCode, error: error));
                  });
                }).catchError((error) {
                  String emailBodyLine1 = '$error';
                  EmailJSService()
                      .sendEmail(Email(
                          username: 'Myself',
                          subject:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          title:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          subtitle:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          body: emailBodyLine1))
                      .then((value) {})
                      .catchError((error) {});
                  store.dispatch(CreateTransactionFailAction(
                      stockCode: action.stockCode, error: error));
                });
                // Then place a BUY order for remaining stocks that are not bought
                {}
              }
            }
          }
          if (thereAreNoIncompleteOrders) {
            // All orders are traded only, so we place a direct BUY or SELL transaction, at market price
            KotakStockAPIService()
                .placeOrder(
                    action.userId,
                    store.state.accessCode,
                    KotakStockAPIPlaceOrderBody(
                        orderType: 'N',
                        instrumentToken: action.instrumentToken,
                        transactionType: action.body.type,
                        quantity: action.body.noOfStocks,
                        price:
                            action.stockOrderType == EStockOrderType.Limit.name
                                ? action.body.stockPrice
                                : 0.0))
                .then((order) {
              bool orderPlacedInNSE =
                  order!.success!.nse != null ? true : false;
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
                      store.dispatch(
                          GetAllDynStocksAction(userId: action.userId));
                    }).catchError((error) {
                      String emailBodyLine1 = '$error';
                      EmailJSService()
                          .sendEmail(Email(
                              username: 'Myself',
                              subject:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              title:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              subtitle:
                                  'Error while creating transaction for DynStock ${action.body.stockCode}',
                              body: emailBodyLine1))
                          .then((value) {})
                          .catchError((error) {});
                      store.dispatch(CreateTransactionFailAction(
                          stockCode: action.stockCode, error: error));
                    });
                  } else {
                    Timer.periodic(Duration(seconds: 3), (timer) {
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
                                          ? order.success!.nse!.orderId
                                              .toString()
                                          : order.success!.bse!.orderId
                                              .toString(),
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
                            store.dispatch(
                                GetAllDynStocksAction(userId: action.userId));
                          }).catchError((error) {
                            String emailBodyLine1 = '$error';
                            EmailJSService()
                                .sendEmail(Email(
                                    username: 'Myself',
                                    subject:
                                        'Error while creating transaction for DynStock ${action.body.stockCode}',
                                    title:
                                        'Error while creating transaction for DynStock ${action.body.stockCode}',
                                    subtitle:
                                        'Error while creating transaction for DynStock ${action.body.stockCode}',
                                    body: emailBodyLine1))
                                .then((value) {})
                                .catchError((error) {});
                            store.dispatch(CreateTransactionFailAction(
                                stockCode: action.stockCode, error: error));
                          });
                        }
                      }).catchError((error) {
                        String emailBodyLine1 = '$error';
                        EmailJSService()
                            .sendEmail(Email(
                                username: 'Myself',
                                subject:
                                    'Error while creating transaction for DynStock ${action.body.stockCode}',
                                title:
                                    'Error while creating transaction for DynStock ${action.body.stockCode}',
                                subtitle:
                                    'Error while creating transaction for DynStock ${action.body.stockCode}',
                                body: emailBodyLine1))
                            .then((value) {})
                            .catchError((error) {});
                        store.dispatch(CreateTransactionFailAction(
                            stockCode: action.stockCode, error: error));
                      });
                    });
                  }
                }).catchError((error) {
                  String emailBodyLine1 = '$error';
                  EmailJSService()
                      .sendEmail(Email(
                          username: 'Myself',
                          subject:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          title:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          subtitle:
                              'Error while creating transaction for DynStock ${action.body.stockCode}',
                          body: emailBodyLine1))
                      .then((value) {})
                      .catchError((error) {});
                  store.dispatch(CreateTransactionFailAction(
                      stockCode: action.stockCode, error: error));
                });
              });

              ///////
            }).catchError((error) {
              String emailBodyLine1 = '$error';
              EmailJSService()
                  .sendEmail(Email(
                      username: 'Myself',
                      subject:
                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                      title:
                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                      subtitle:
                          'Error while creating transaction for DynStock ${action.body.stockCode}',
                      body: emailBodyLine1))
                  .then((value) {})
                  .catchError((error) {});
              store.dispatch(CreateTransactionFailAction(
                  stockCode: action.stockCode, error: error));
            });
          }
        }).catchError((error) {
          String emailBodyLine1 = '$error';
          EmailJSService()
              .sendEmail(Email(
                  username: 'Myself',
                  subject:
                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                  title:
                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                  subtitle:
                      'Error while creating transaction for DynStock ${action.body.stockCode}',
                  body: emailBodyLine1))
              .then((value) {})
              .catchError((error) {});
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
        store.dispatch(GetAllDynStocksAction(userId: action.userId));
      }).catchError((error) {
        String emailBodyLine1 = '$error';
        EmailJSService()
            .sendEmail(Email(
                username: 'Myself',
                subject:
                    'Error while creating transaction for DynStock ${action.body.stockCode}',
                title:
                    'Error while creating transaction for DynStock ${action.body.stockCode}',
                subtitle:
                    'Error while creating transaction for DynStock ${action.body.stockCode}',
                body: emailBodyLine1))
            .then((value) {})
            .catchError((error) {});
        store.dispatch(CreateTransactionFailAction(
            stockCode: action.stockCode, error: error));
      });
    }
  }
  next(action);
}
