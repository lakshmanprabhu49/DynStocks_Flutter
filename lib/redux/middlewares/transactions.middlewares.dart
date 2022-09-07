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

Future<int> modifyPartialOrdersToFullOrders(Store<AppState> store,
    CreateTransactionAction action, int partiallyTradedOrderId) async {
  // Get the order report
  try {
    KotakStockApiOrderReportsResponse orderReports =
        await KotakStockAPIService().getOrderReport(
            action.userId,
            store.state.accessCode,
            partiallyTradedOrderId,
            action.instrumentToken) as KotakStockApiOrderReportsResponse;
    var orderReport = orderReports.success[0];
    int quantityTradedAlready =
        orderReport.orderQuantity - orderReport.pendingQuantity;
    // Modify the partially traded order such that it's fully traded
    KotakStockApiPlaceOrderResponse modifiedOrder = await KotakStockAPIService()
            .modifyOrder(
                action.userId,
                store.state.accessCode,
                partiallyTradedOrderId,
                KotakStockAPIPlaceOrderBody(
                    orderType: 'N',
                    instrumentToken: action.instrumentToken,
                    transactionType: orderReport.transactionType,
                    quantity: quantityTradedAlready))
        as KotakStockApiPlaceOrderResponse;
    bool orderPlacedInNSE = modifiedOrder.success!.nse != null ? true : false;
    await TransactionsService().createTransaction(
        action.userId,
        action.dynStockId,
        TransactionBody(
            transactionId: orderPlacedInNSE
                ? modifiedOrder.success!.nse!.orderId.toString()
                : modifiedOrder.success!.bse!.orderId.toString(),
            type: action.body.type,
            noOfStocks: quantityTradedAlready,
            stockCode: action.body.stockCode,
            stockPrice: orderReport.price));
    return orderReport.pendingQuantity;
  } catch (error) {
    print(error);
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
        .catchError((error) {
      print(error);
    });
    store.dispatch(
        CreateTransactionFailAction(stockCode: action.stockCode, error: error));
    return -1;
  }
}

Future<void> placeFullOrders(
    Store<AppState> store, CreateTransactionAction action) async {
  try {
    KotakStockApiPlaceOrderResponse order = await KotakStockAPIService()
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
                    : 0.0)) as KotakStockApiPlaceOrderResponse;
    bool orderPlacedInNSE = order.success!.nse != null ? true : false;
    Future.delayed(Duration(milliseconds: 200), () async {
      KotakStockApiOrderReportsResponse position = await KotakStockAPIService()
          .getOrderReport(
              action.userId,
              store.state.accessCode,
              (orderPlacedInNSE
                  ? order.success!.nse!.orderId
                  : order.success!.bse!.orderId),
              action.instrumentToken) as KotakStockApiOrderReportsResponse;
      OrderReportsSuccess tradedStock = position.success.firstWhere((element) =>
          element.orderId ==
          (orderPlacedInNSE
              ? order.success!.nse!.orderId
              : order.success!.bse!.orderId));
      int orderId = orderPlacedInNSE
          ? order.success!.nse!.orderId
          : order.success!.bse!.orderId;
      if (tradedStock.status == EStockTradeStatus.TRAD.name) {
        Transaction response = await TransactionsService().createTransaction(
            action.userId,
            action.dynStockId,
            TransactionBody(
                transactionId: orderPlacedInNSE
                    ? order.success!.nse!.orderId.toString()
                    : order.success!.bse!.orderId.toString(),
                type: action.body.type,
                noOfStocks: action.body.noOfStocks,
                stockCode: action.body.stockCode,
                stockPrice: tradedStock.price));
        store.dispatch(
            CreateTransactionSuccessAction(stockCode: action.stockCode));
        store.state.allTickerData.data[action.stockCode]!
            .currentLocalMaximumPrice = tradedStock.price;
        store.state.allTickerData.data[action.stockCode]!
            .currentLocalMinimumPrice = tradedStock.price;
        store.dispatch(GetAllTickerDataSuccessAction(
            allTickerData: store.state.allTickerData.data));
        store.dispatch(GetAllDynStocksAction(userId: action.userId));
      } else {
        Timer.periodic(Duration(seconds: 3), (timer) async {
          KotakStockApiOrderReportsResponse position =
              await KotakStockAPIService().getOrderReport(
                  action.userId,
                  store.state.accessCode,
                  (orderPlacedInNSE
                      ? order.success!.nse!.orderId
                      : order.success!.bse!.orderId),
                  action.instrumentToken) as KotakStockApiOrderReportsResponse;
          OrderReportsSuccess tradedStock = position.success.firstWhere(
              (element) =>
                  element.orderId ==
                  (orderPlacedInNSE
                      ? order.success!.nse!.orderId
                      : order.success!.bse!.orderId));
          int orderId = orderPlacedInNSE
              ? order.success!.nse!.orderId
              : order.success!.bse!.orderId;
          if (tradedStock.status == EStockTradeStatus.TRAD.name) {
            timer.cancel();
            Transaction response = await TransactionsService()
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
                        stockPrice: tradedStock.price));
            store.dispatch(CreateTransactionSuccessAction(
              stockCode: action.stockCode,
            ));
            store.state.allTickerData.data[action.stockCode]!
                .currentLocalMaximumPrice = tradedStock.price;
            store.state.allTickerData.data[action.stockCode]!
                .currentLocalMinimumPrice = tradedStock.price;
            store.dispatch(GetAllTickerDataSuccessAction(
                allTickerData: store.state.allTickerData.data));
            store.dispatch(GetAllDynStocksAction(userId: action.userId));
          } else if (tradedStock.status == EStockTradeStatus.CAN.name) {
            timer.cancel();
            store.dispatch(CreateTransactionSuccessAction(
              stockCode: action.stockCode,
            ));
            store.dispatch(GetAllDynStocksAction(userId: action.userId));
          }
        });
      }
    });
  } catch (error) {
    print(error);
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
        .catchError((error) {
      print(error);
    });
    store.dispatch(
        CreateTransactionFailAction(stockCode: action.stockCode, error: error));
  }
  //////////////
  /** 
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
        if (tradedStock.status == EStockTradeStatus.TRAD.name) {
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
            store.dispatch(
                CreateTransactionSuccessAction(stockCode: action.stockCode));
            store.state.allTickerData.data[action.stockCode]!
                .currentLocalMaximumPrice = tradedStock.price;
            store.state.allTickerData.data[action.stockCode]!
                .currentLocalMinimumPrice = tradedStock.price;
            store.dispatch(GetAllTickerDataSuccessAction(
                allTickerData: store.state.allTickerData.data));
            store.dispatch(GetAllDynStocksAction(userId: action.userId));
          }).catchError((error) {
            print(error);
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
                .catchError((error) {
              print(error);
            });
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
              OrderReportsSuccess tradedStock = position!.success.firstWhere(
                  (element) =>
                      element.orderId ==
                      (orderPlacedInNSE
                          ? order.success!.nse!.orderId
                          : order.success!.bse!.orderId));
              int orderId = orderPlacedInNSE
                  ? order.success!.nse!.orderId
                  : order.success!.bse!.orderId;
              if (tradedStock.status == EStockTradeStatus.TRAD.name) {
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
                  store.dispatch(GetAllDynStocksAction(userId: action.userId));
                }).catchError((error) {
                  print(error);
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
                      .catchError((error) {
                    print(error);
                  });
                  store.dispatch(CreateTransactionFailAction(
                      stockCode: action.stockCode, error: error));
                });
              } else if (tradedStock.status == EStockTradeStatus.CAN.name) {
                timer.cancel();
                store.dispatch(CreateTransactionSuccessAction(
                  stockCode: action.stockCode,
                ));
                store.dispatch(GetAllDynStocksAction(userId: action.userId));
              }
            }).catchError((error) {
              print(error);
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
                  .catchError((error) {
                print(error);
              });
              store.dispatch(CreateTransactionFailAction(
                  stockCode: action.stockCode, error: error));
            });
          });
        }
      }).catchError((error) {
        print(error);
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
            .catchError((error) {
          print(error);
        });
        store.dispatch(CreateTransactionFailAction(
            stockCode: action.stockCode, error: error));
      });
    });

    ///////
  }).catchError((error) {
    print(error);
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
        .catchError((error) {
      print(error);
    });
    store.dispatch(
        CreateTransactionFailAction(stockCode: action.stockCode, error: error));
  });
  */
}

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
      print(error);
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
          .catchError((error) {
        print(error);
      });
      store.dispatch(GetAllTransactionsFailAction(error: error));
    });
  }
  if (action is CreateTransactionAction) {
    if (action.placeKotakAPIStockOrder) {
      if (!action.forcedTransaction) {
        if (!(store
            .state.transactionsCreateState.data[action.stockCode]!.creating)) {
          await placeFullOrders(store, action);
        }
      } else {
        KotakStockAPIService()
            .getOrderCategories(
                action.userId, store.state.accessCode, action.instrumentToken)
            .then((orderCategories) async {
          try {
            // For OPEN Orders we just cancel them.
            orderCategories!.OPN.forEach((openOrderId) async {
              var res = await KotakStockAPIService().cancelOrder(
                  action.userId, store.state.accessCode, openOrderId);
            });
            // Depending of the nature of the forced transaction (BUY/SELL),
            // For Partially traded orders
            bool thereWerePartialOrders = orderCategories.OPF.length > 0;
            orderCategories.OPF.forEach((partiallyTradedOrderId) async {
              // First modify the partial orders to fully traded orders
              int pendingQuantity = await modifyPartialOrdersToFullOrders(
                  store, action, partiallyTradedOrderId);
              action.body.noOfStocks = pendingQuantity;
              action.stockOrderType = EStockOrderType.Market.name;
              await placeFullOrders(store, action);
              // Then place the order for remaining quantity at market price
            });

            // If there were no partial orders, then place orders at the market price
            if (!thereWerePartialOrders) {
              await placeFullOrders(store, action);
            }
          } catch (error) {
            print(error);
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
                .catchError((error) {
              print(error);
            });
            store.dispatch(CreateTransactionFailAction(
                stockCode: action.stockCode, error: error));
          }
        }).catchError((error) {
          print(error);
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
              .catchError((error) {
            print(error);
          });
          store.dispatch(CreateTransactionFailAction(
              stockCode: action.stockCode, error: error));
        });
        /////////////
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
        print(error);
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
            .catchError((error) {
          print(error);
        });
        store.dispatch(CreateTransactionFailAction(
            stockCode: action.stockCode, error: error));
      });
    }
  }
  next(action);
}
