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
import 'package:dynstocks/services/gmail_error_message.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:dynstocks/services/transactions.service.dart';
import 'package:dynstocks/static/last_dispatched_order_time.dart';
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
    if (((error as dynamic).message as String)
        .toLowerCase()
        .contains('quota')) {
      return modifyPartialOrdersToFullOrders(
          store, action, partiallyTradedOrderId);
    } else {
      store.dispatch(CreateTransactionFailAction(
          stockCode: action.stockCode, error: error));
      String emailBodyLine1 = '$error';
      // GmailErrorMessageService.sendEmail(
      //         'Error while creating transaction for DynStock ${action.body.stockCode}',
      //         '<h2>Error while creating transaction for DynStock ${action.body.stockCode} for user ${store.state.username}</h2><br/><p>${emailBodyLine1}</p>')
      //     .then((value) {})
      //     .catchError((error) {
      //   print(error);
      // });
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
      return -1;
    }
  }
}

Future<void> placeFullOrders(
    Store<AppState> store, CreateTransactionAction action,
    {bool placeOrder = true,
    KotakStockApiPlaceOrderResponse? placedOrder}) async {
  bool placedOrder = false;
  KotakStockApiPlaceOrderResponse? order;
  try {
    if (placeOrder) {
      LastDispatchedOrderTime.data[action.stockCode] = DateTime.now();
      order = await KotakStockAPIService().placeOrder(
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
    } else {
      order = placedOrder as KotakStockApiPlaceOrderResponse;
    }
    placedOrder = true;
    bool orderPlacedInNSE = order.success!.nse != null ? true : false;
    Future.delayed(Duration(milliseconds: 200), () async {
      try {
        KotakStockApiOrderReportsResponse position =
            await KotakStockAPIService().getOrderReport(
                action.userId,
                store.state.accessCode,
                (orderPlacedInNSE
                    ? order!.success!.nse!.orderId
                    : order!.success!.bse!.orderId),
                action.instrumentToken) as KotakStockApiOrderReportsResponse;
        OrderReportsSuccess tradedStock = position.success.firstWhere(
            (element) =>
                element.orderId ==
                (orderPlacedInNSE
                    ? order!.success!.nse!.orderId
                    : order!.success!.bse!.orderId));
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
          Timer.periodic(Duration(seconds: 5), (timer) async {
            try {
              KotakStockApiOrderReportsResponse position =
                  await KotakStockAPIService().getOrderReport(
                          action.userId,
                          store.state.accessCode,
                          (orderPlacedInNSE
                              ? order!.success!.nse!.orderId
                              : order!.success!.bse!.orderId),
                          action.instrumentToken)
                      as KotakStockApiOrderReportsResponse;
              OrderReportsSuccess tradedStock = position.success.firstWhere(
                  (element) =>
                      element.orderId ==
                      (orderPlacedInNSE
                          ? order!.success!.nse!.orderId
                          : order!.success!.bse!.orderId));
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
              } else if (tradedStock.status == EStockTradeStatus.OPN.name) {
                // Check if the order can be further optimized
                // if (tradedStock.transactionType == ETransactionType.SELL.name &&
                //     store.state.allTickerData.data[action.stockCode]!.price
                //             .currentPrice! >
                //         tradedStock.price) {
                //   KotakStockApiPlaceOrderResponse newModifiedOrder =
                //       await KotakStockAPIService().modifyOrder(
                //               action.userId,
                //               store.state.accessCode,
                //               tradedStock.orderId,
                //               KotakStockAPIPlaceOrderBody(
                //                   orderType: 'N',
                //                   instrumentToken: action.instrumentToken,
                //                   transactionType: tradedStock.transactionType,
                //                   quantity: tradedStock.orderQuantity,
                //                   price: store
                //                       .state
                //                       .allTickerData
                //                       .data[action.stockCode]!
                //                       .price
                //                       .currentPrice!))
                //           as KotakStockApiPlaceOrderResponse;
                // } else if (tradedStock.transactionType ==
                //         ETransactionType.BUY.name &&
                //     store.state.allTickerData.data[action.stockCode]!.price
                //             .currentPrice! <
                //         tradedStock.price) {
                //   KotakStockApiPlaceOrderResponse newModifiedOrder =
                //       await KotakStockAPIService().modifyOrder(
                //               action.userId,
                //               store.state.accessCode,
                //               tradedStock.orderId,
                //               KotakStockAPIPlaceOrderBody(
                //                   orderType: 'N',
                //                   instrumentToken: action.instrumentToken,
                //                   transactionType: tradedStock.transactionType,
                //                   quantity: tradedStock.orderQuantity,
                //                   price: store
                //                       .state
                //                       .allTickerData
                //                       .data[action.stockCode]!
                //                       .price
                //                       .currentPrice!))
                //           as KotakStockApiPlaceOrderResponse;
                // }
              }
            } catch (error) {
              if (((error as dynamic).message as String)
                  .toLowerCase()
                  .contains('quota')) {
                if (placedOrder) {
                  placeFullOrders(store, action,
                      placeOrder: false, placedOrder: order);
                } else {
                  placeFullOrders(store, action);
                }
              } else {
                store.dispatch(CreateTransactionFailAction(
                    stockCode: action.stockCode, error: error));
                String emailBodyLine1 = '$error';
                // GmailErrorMessageService.sendEmail(
                //         'Error while creating transaction for DynStock ${action.body.stockCode}',
                //         '<h2>Error while creating transaction for DynStock ${action.body.stockCode} for user ${store.state.username}</h2><br/><p>${emailBodyLine1}</p>')
                //     .then((value) {})
                //     .catchError((error) {
                //   print(error);
                // });
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
              }
            }
          });
        }
      } catch (error) {
        if (((error as dynamic).message as String)
            .toLowerCase()
            .contains('quota')) {
          if (placedOrder) {
            placeFullOrders(store, action,
                placeOrder: false, placedOrder: order);
          } else {
            placeFullOrders(store, action);
          }
        } else {
          store.dispatch(CreateTransactionFailAction(
              stockCode: action.stockCode, error: error));
          String emailBodyLine1 = '$error';
          // GmailErrorMessageService.sendEmail(
          //         'Error while creating transaction for DynStock ${action.body.stockCode}',
          //         '<h2>Error while creating transaction for DynStock ${action.body.stockCode} for user ${store.state.username}</h2><br/><p>${emailBodyLine1}</p>')
          //     .then((value) {})
          //     .catchError((error) {
          //   print(error);
          // });
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
        }
      }
    });
  } catch (error) {
    if (((error as dynamic).message as String)
        .toLowerCase()
        .contains('quota')) {
      if (placedOrder) {
        placeFullOrders(store, action, placeOrder: false, placedOrder: order);
      } else {
        placeFullOrders(store, action);
      }
    } else {
      store.dispatch(CreateTransactionFailAction(
          stockCode: action.stockCode, error: error));
      String emailBodyLine1 = '$error';
      // GmailErrorMessageService.sendEmail(
      //         'Error while creating transaction for DynStock ${action.body.stockCode}',
      //         '<h2>Error while creating transaction for DynStock ${action.body.stockCode} for user ${store.state.username}</h2><br/><p>${emailBodyLine1}</p>')
      //     .then((value) {})
      //     .catchError((error) {
      //   print(error);
      // });
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
    }
  }
}

void transactionsMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetAllTransactionsAction) {
    try {
      TransactionsResponse response = await TransactionsService()
          .getTransactionsForDate(action.userId,
              date: action.date,
              limit: action.limit,
              offset: action.offset,
              sortCriterion: action.sortCriterion,
              sortDirection: action.sortDirection,
              dynStockId: action.dynStockId,
              filterCriterionStocks: action.filterCriterionStocks,
              filterCriterionDay: action.filterCriterionDay);
      store.dispatch(GetAllTransactionsSuccessAction(data: response));
    } catch (error) {
      print(error);
      String emailBodyLine1 = '$error';
      // GmailErrorMessageService.sendEmail(
      //         'Error while getting all transactions for DynStock ${action.dynStockId}',
      //         '<h2>Error while getting all transactions for DynStock ${action.dynStockId} for user ${store.state.username}</h2><br/><p>${emailBodyLine1}</p>')
      //     .then((value) {})
      //     .catchError((error) {
      //   print(error);
      // });
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
    }
  }
  if (action is CreateTransactionAction) {
    if (action.placeKotakAPIStockOrder) {
      if (!action.forcedTransaction) {
        if (!LastDispatchedOrderTime.data.containsKey(action.stockCode)) {
          LastDispatchedOrderTime.data[action.stockCode] = DateTime(2020);
        }
        DateTime lastDispatchedOrderTime =
            LastDispatchedOrderTime.data[action.stockCode] as DateTime;
        DateTime now = DateTime.now();
        Duration difference = now.difference(lastDispatchedOrderTime);
        if (!(store.state.transactionsCreateState.data[action.stockCode]!
                .creating) &&
            difference.inMinutes >= 1) {
          try {
            // Sometimes , creating is not working properly,
            // So what we do is, get order Categories, check if there are any open orders
            // If yes, don't place Full Order
            OrderCategories orderCategories = await KotakStockAPIService()
                .getOrderCategories(action.userId, store.state.accessCode,
                    action.instrumentToken) as OrderCategories;
            if (orderCategories.OPN.isNotEmpty ||
                orderCategories.OPF.isNotEmpty) {
              store.dispatch(
                  CreateTransactionSuccessAction(stockCode: action.stockCode));
            } else {
              await placeFullOrders(store, action);
            }
          } catch (error) {
            if (((error as dynamic).message as String)
                .toLowerCase()
                .contains('quota')) {
              store.dispatch(
                  CreateTransactionFailAction(stockCode: action.stockCode));
              store.dispatch(action);
            } else {
              store.dispatch(CreateTransactionFailAction(
                  stockCode: action.stockCode, error: error));
              print(error);
              String emailBodyLine1 = '$error';
              // GmailErrorMessageService.sendEmail(
              //         'Error while creating transaction for DynStock ${action.body.stockCode}',
              //         '<h2>Error while creating transaction for DynStock ${action.body.stockCode} for user ${store.state.username}</h2><br/><p>${emailBodyLine1}</p>')
              //     .then((value) {})
              //     .catchError((error) {
              //   print(error);
              // });
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
            }
          }
        }
      } else {
        try {
          OrderCategories orderCategories = await KotakStockAPIService()
              .getOrderCategories(action.userId, store.state.accessCode,
                  action.instrumentToken) as OrderCategories;
          // For OPEN Orders we just cancel them.
          await Future.forEach(orderCategories.OPN, (openOrderId) async {
            var res = await KotakStockAPIService().cancelOrder(
                action.userId, store.state.accessCode, openOrderId as int);
          });
          // orderCategories!.OPN.forEach((openOrderId) async {
          //   var res = await KotakStockAPIService().cancelOrder(
          //       action.userId, store.state.accessCode, openOrderId);
          // });
          // Depending of the nature of the forced transaction (BUY/SELL),
          // For Partially traded orders
          bool thereWerePartialOrders = orderCategories.OPF.isNotEmpty;
          await Future.forEach(orderCategories.OPF,
              (partiallyTradedOrderId) async {
            // First modify the partial orders to fully traded orders
            int pendingQuantity = await modifyPartialOrdersToFullOrders(
                store, action, partiallyTradedOrderId as int);
            action.body.noOfStocks = pendingQuantity;
            action.stockOrderType = EStockOrderType.Market.name;
            await placeFullOrders(store, action);
            // Then place the order for remaining quantity at market price
          });
          // orderCategories.OPF.forEach((partiallyTradedOrderId) async {
          //   // First modify the partial orders to fully traded orders
          //   int pendingQuantity = await modifyPartialOrdersToFullOrders(
          //       store, action, partiallyTradedOrderId);
          //   action.body.noOfStocks = pendingQuantity;
          //   action.stockOrderType = EStockOrderType.Market.name;
          //   await placeFullOrders(store, action);
          //   // Then place the order for remaining quantity at market price
          // });

          // If there were no partial orders, then place orders at the market price
          if (!thereWerePartialOrders) {
            await placeFullOrders(store, action);
          }
        } catch (error) {
          if (((error as dynamic).message as String)
              .toLowerCase()
              .contains('quota')) {
            store.dispatch(
                CreateTransactionFailAction(stockCode: action.stockCode));
            store.dispatch(action);
          } else {
            store.dispatch(CreateTransactionFailAction(
                stockCode: action.stockCode, error: error));
            print(error);
            String emailBodyLine1 = '$error';
            // GmailErrorMessageService.sendEmail(
            //         'Error while creating transaction for DynStock ${action.body.stockCode}',
            //         '<h2>Error while creating transaction for DynStock ${action.body.stockCode} for user ${store.state.username}</h2><br/><p>${emailBodyLine1}</p>')
            //     .then((value) {})
            //     .catchError((error) {
            //   print(error);
            // });
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
          }
        }
        /////////////
      }
    } else {
      try {
        Transaction response = await TransactionsService().createTransaction(
            action.userId,
            action.dynStockId,
            TransactionBody(
                transactionId: action.body.transactionId,
                type: action.body.type,
                noOfStocks: action.body.noOfStocks,
                stockCode: action.body.stockCode,
                stockPrice: action.body.stockPrice));
        store.dispatch(
            CreateTransactionSuccessAction(stockCode: action.stockCode));
        store.state.allTickerData.data[action.stockCode]!
            .currentLocalMaximumPrice = action.body.stockPrice;
        store.state.allTickerData.data[action.stockCode]!
            .currentLocalMinimumPrice = action.body.stockPrice;
        store.dispatch(GetAllTickerDataSuccessAction(
            allTickerData: store.state.allTickerData.data));
        store.dispatch(GetAllDynStocksAction(userId: action.userId));
      } catch (error) {
        print(error);
        store.dispatch(CreateTransactionFailAction(
            stockCode: action.stockCode, error: error));
        String emailBodyLine1 = '$error';
        // GmailErrorMessageService.sendEmail(
        //         'Error while creating transaction for DynStock ${action.body.stockCode}',
        //         '<h2>Error while creating transaction for DynStock ${action.body.stockCode} for user ${store.state.username}</h2><br/><p>${emailBodyLine1}</p>')
        //     .then((value) {})
        //     .catchError((error) {
        //   print(error);
        // });
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
      }
    }
  }
  next(action);
}
