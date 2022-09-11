import 'dart:async';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/dyn_stocks.service.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:dynstocks/services/transactions.service.dart';
import 'package:redux/redux.dart';

Future<int> modifyPartialOrdersToFullOrders(
    Store<AppState> store,
    DeleteDynStockAction action,
    int partiallyTradedOrderId,
    DynStock dynStockToBeDeleted,
    ETransactionType transactionType) async {
  // Get the order report
  try {
    KotakStockApiOrderReportsResponse orderReports =
        await KotakStockAPIService().getOrderReport(
                action.userId,
                store.state.accessCode,
                partiallyTradedOrderId,
                dynStockToBeDeleted.instrumentToken)
            as KotakStockApiOrderReportsResponse;
    var orderReport = orderReports.success[0];
    int quantityTradedAlready =
        orderReport.orderQuantity - orderReport.pendingQuantity;
    KotakStockApiPlaceOrderResponse modifiedOrder = KotakStockAPIService()
            .modifyOrder(
                action.userId,
                store.state.accessCode,
                orderReport.orderId,
                KotakStockAPIPlaceOrderBody(
                    orderType: 'N',
                    instrumentToken: dynStockToBeDeleted.instrumentToken,
                    transactionType: transactionType.name,
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
            type: transactionType.name,
            noOfStocks: quantityTradedAlready,
            stockCode: action.stockCode,
            stockPrice: orderReport.price));
    if (transactionType == ETransactionType.SELL) {
      return orderReport.pendingQuantity;
    } else {
      return quantityTradedAlready;
    }
  } catch (error) {
    pauseTransactions[action.stockCode] = false;
    print(error);
    String emailBodyLine1 = '$error';
    EmailJSService()
        .sendEmail(Email(
            username: 'Myself',
            subject: 'Error while Deleting DynStock ${action.stockCode}',
            title: 'Error while Deleting DynStock ${action.stockCode}',
            subtitle: 'Error while Deleting DynStock ${action.stockCode}',
            body: emailBodyLine1))
        .then((value) {})
        .catchError((error) {
      print(error);
      store.dispatch(DeleteDynStockFailAction(error: error));
    });
    return -1;
  }
}

Future<void> placeFullOrderAndDeleteDynStock(
    Store<AppState> store,
    DeleteDynStockAction action,
    DynStock dynStockToBeDeleted,
    int quantity,
    ETransactionType transactionType) async {
  try {
    KotakStockApiPlaceOrderResponse newOrder = await KotakStockAPIService()
        .placeOrder(
            action.userId,
            store.state.accessCode,
            KotakStockAPIPlaceOrderBody(
                orderType: 'N',
                instrumentToken: dynStockToBeDeleted.instrumentToken,
                transactionType: transactionType.name,
                quantity: quantity)) as KotakStockApiPlaceOrderResponse;
    bool orderPlacedInNSE = newOrder.success!.nse != null ? true : false;
    Future.delayed(Duration(milliseconds: 200), () async {
      try {
        KotakStockApiOrderReportsResponse position =
            await KotakStockAPIService().getOrderReport(
                    action.userId,
                    store.state.accessCode,
                    (orderPlacedInNSE
                        ? newOrder.success!.nse!.orderId
                        : newOrder.success!.bse!.orderId),
                    dynStockToBeDeleted.instrumentToken)
                as KotakStockApiOrderReportsResponse;
        OrderReportsSuccess tradedStock = position.success.firstWhere(
            (element) =>
                element.orderId ==
                (orderPlacedInNSE
                    ? newOrder.success!.nse!.orderId
                    : newOrder.success!.bse!.orderId));
        int orderId = orderPlacedInNSE
            ? newOrder.success!.nse!.orderId
            : newOrder.success!.bse!.orderId;
        if (tradedStock.status == EStockTradeStatus.TRAD.name) {
          Transaction transactionResponse = await TransactionsService()
              .createTransaction(
                  action.userId,
                  action.dynStockId,
                  TransactionBody(
                      transactionId: orderPlacedInNSE
                          ? newOrder.success!.nse!.orderId.toString()
                          : newOrder.success!.bse!.orderId.toString(),
                      type: transactionType.name,
                      noOfStocks: quantity,
                      stockCode: action.stockCode,
                      stockPrice: tradedStock.price));
          String response = await DynStocksService()
              .deleteDynStock(action.userId, action.dynStockId);
          pauseTransactions[action.stockCode] = false;
          store.dispatch(CreateTransactionSuccessAction(
              stockCode: dynStockToBeDeleted.stockCode));
          store.dispatch(DeleteDynStockSuccessAction(dynStockId: response));
        } else {
          Timer.periodic(Duration(seconds: 5), (timer) async {
            try {
              KotakStockApiOrderReportsResponse position =
                  KotakStockAPIService().getOrderReport(
                          action.userId,
                          store.state.accessCode,
                          (orderPlacedInNSE
                              ? newOrder.success!.nse!.orderId
                              : newOrder.success!.bse!.orderId),
                          dynStockToBeDeleted.instrumentToken)
                      as KotakStockApiOrderReportsResponse;
              OrderReportsSuccess tradedStock = position.success.firstWhere(
                  (element) =>
                      element.orderId ==
                      (orderPlacedInNSE
                          ? newOrder.success!.nse!.orderId
                          : newOrder.success!.bse!.orderId));
              int orderId = orderPlacedInNSE
                  ? newOrder.success!.nse!.orderId
                  : newOrder.success!.bse!.orderId;
              if (tradedStock.status == EStockTradeStatus.TRAD.name) {
                timer.cancel();
                Transaction transactionResponse = await TransactionsService()
                    .createTransaction(
                        action.userId,
                        action.dynStockId,
                        TransactionBody(
                            transactionId: orderPlacedInNSE
                                ? newOrder.success!.nse!.orderId.toString()
                                : newOrder.success!.bse!.orderId.toString(),
                            type: ETransactionType.SELL.name,
                            noOfStocks: quantity,
                            stockCode: action.stockCode,
                            stockPrice: tradedStock.price));
                String response = await DynStocksService()
                    .deleteDynStock(action.userId, action.dynStockId);
                store.dispatch(CreateTransactionSuccessAction(
                    stockCode: dynStockToBeDeleted.stockCode));
                pauseTransactions[action.stockCode] = false;
                store.dispatch(
                    DeleteDynStockSuccessAction(dynStockId: response));
              } else if (tradedStock.status == EStockTradeStatus.CAN.name) {
                timer.cancel();
                String response = await DynStocksService()
                    .deleteDynStock(action.userId, action.dynStockId);
                store.dispatch(CreateTransactionSuccessAction(
                    stockCode: dynStockToBeDeleted.stockCode));
                pauseTransactions[action.stockCode] = false;
                store.dispatch(
                    DeleteDynStockSuccessAction(dynStockId: response));
              }
            } catch (error) {
              print(error);
              pauseTransactions[action.stockCode] = false;
              String emailBodyLine1 = '$error';
              EmailJSService()
                  .sendEmail(Email(
                      username: 'Myself',
                      subject:
                          'Error while Deleting DynStock ${action.stockCode}',
                      title:
                          'Error while Deleting DynStock ${action.stockCode}',
                      subtitle:
                          'Error while Deleting DynStock ${action.stockCode}',
                      body: emailBodyLine1))
                  .then((value) {})
                  .catchError((error) {
                print(error);
              });
              store.dispatch(DeleteDynStockFailAction(error: error));
            }
          });
        }
      } catch (error) {
        print(error);
        pauseTransactions[action.stockCode] = false;
        String emailBodyLine1 = '$error';
        EmailJSService()
            .sendEmail(Email(
                username: 'Myself',
                subject: 'Error while Deleting DynStock ${action.stockCode}',
                title: 'Error while Deleting DynStock ${action.stockCode}',
                subtitle: 'Error while Deleting DynStock ${action.stockCode}',
                body: emailBodyLine1))
            .then((value) {})
            .catchError((error) {
          print(error);
        });
        store.dispatch(DeleteDynStockFailAction(error: error));
      }
    });
  } catch (error) {
    print(error);
    pauseTransactions[action.stockCode] = false;
    String emailBodyLine1 = '$error';
    EmailJSService()
        .sendEmail(Email(
            username: 'Myself',
            subject: 'Error while Deleting DynStock ${action.stockCode}',
            title: 'Error while Deleting DynStock ${action.stockCode}',
            subtitle: 'Error while Deleting DynStock ${action.stockCode}',
            body: emailBodyLine1))
        .then((value) {})
        .catchError((error) {
      print(error);
    });
    store.dispatch(DeleteDynStockFailAction(error: error));
  }
}

void dynStocksMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetAllDynStocksAction) {
    DynStocksService().getDynStocks(action.userId).then((response) {
      store.dispatch(GetAllDynStocksSuccessAction(allDynStocks: response));
      Map<String, TransactionsCreate> map =
          Map<String, TransactionsCreate>.from(
              store.state.transactionsCreateState.data);
      bool mapAltered = false;
      Set<String> dynStocksForUser = {};
      for (DynStock dynStock in response) {
        dynStocksForUser.add(dynStock.stockCode);
        if (map[dynStock.stockCode] == null) {
          mapAltered = true;
          map[dynStock.stockCode] = TransactionsCreate(
              creating: false, created: false, createFailed: false);
          pauseTransactions[dynStock.stockCode] = false;
        }
        pauseTransactions[dynStock.stockCode] = false;
      }
      Set<String> previousDynStocksForUser = {};
      previousDynStocksForUser.addAll(map.keys);
      Set<String> dynStocksDeleted =
          previousDynStocksForUser.difference(dynStocksForUser);
      if (dynStocksDeleted.isNotEmpty) {
        mapAltered = true;
        dynStocksDeleted.forEach((element) {
          map.remove(element);
          pauseTransactions.remove(element);
        });
      }
      if (mapAltered) {
        store.dispatch(InitializeCreateTransactionStateAction(data: map));
      }
    }).catchError((error) {
      print(error);
      String emailBodyLine1 = '$error';
      EmailJSService()
          .sendEmail(Email(
              username: 'Myself',
              subject: 'Error while Fetching List of DynStocks',
              title: 'Error while Fetching List of DynStocks',
              subtitle:
                  'The following error resulted while Fetching List of DynStocks',
              body: emailBodyLine1))
          .then((value) {})
          .catchError((error) {
        print(error);
      });
      store.dispatch(GetAllDynStocksFailAction(error: error));
    });
  }

  if (action is CreateDynStockAction) {
    KotakStockAPIService()
        .placeOrder(
            action.userId,
            appStore.state.accessCode,
            KotakStockAPIPlaceOrderBody(
                orderType: 'N',
                instrumentToken: action.body.instrumentToken,
                transactionType: 'BUY',
                quantity: action.body.noOfStocks,
                price: 0))
        .then(
      (order) {
        bool orderPlacedInNSE = order!.success!.nse != null ? true : false;
        PlaceOrderData? orderData =
            orderPlacedInNSE ? order.success!.nse : order.success!.bse;
        action.body.transactionForCreateDynStock = TransactionBody(
            transactionId: orderData!.orderId.toString(),
            type: 'BUY',
            noOfStocks: orderData.quantity,
            stockCode: action.body.stockCode,
            stockPrice: action.price);
        Future.delayed(Duration(milliseconds: 200), () {
          KotakStockAPIService()
              .getOrderReport(action.userId, appStore.state.accessCode,
                  orderData.orderId, action.body.instrumentToken)
              .then((position) {
            action.body.transactionForCreateDynStock!.stockPrice = position!
                .success
                .firstWhere((element) => element.orderId == orderData.orderId)
                .price;
            DynStocksService()
                .createDynStock(action.userId, action.body)
                .then((response) {
              store.dispatch(CreateDynStockSuccessAction(dynStock: response));
              if (!store.state.allTickerData.loading) {
                store.dispatch(GetAllTickerDataAction());
              }
            }).catchError((error) {
              print(error);
              String emailBodyLine1 = '$error';
              EmailJSService()
                  .sendEmail(Email(
                      username: 'Myself',
                      subject: 'Error while Creating DynStock',
                      title:
                          'Error while Creating DynStock for ${action.body.stockCode}',
                      subtitle:
                          'The following error resulted while Creating DynStock for ${action.body.stockCode}',
                      body: emailBodyLine1))
                  .then((value) {})
                  .catchError((error) {
                print(error);
              });
              store.dispatch(CreateDynStockFailAction(error: error));
            });
          }).catchError((error) {
            print(error);
            String emailBodyLine1 = '$error';
            EmailJSService()
                .sendEmail(Email(
                    username: 'Myself',
                    subject: 'Error while Creating DynStock',
                    title:
                        'Error while Creating DynStock for ${action.body.stockCode}',
                    subtitle:
                        'The following error resulted while Creating DynStock for ${action.body.stockCode}',
                    body: emailBodyLine1))
                .then((value) {})
                .catchError((error) {
              print(error);
            });
            store.dispatch(CreateDynStockFailAction(error: error));
          });
        });
      },
    ).catchError((error) {
      print(error);
      String emailBodyLine1 = '$error';
      EmailJSService()
          .sendEmail(Email(
              username: 'Myself',
              subject: 'Error while Creating DynStock',
              title:
                  'Error while Creating DynStock for ${action.body.stockCode}',
              subtitle:
                  'The following error resulted while Creating DynStock for ${action.body.stockCode}',
              body: emailBodyLine1))
          .then((value) {})
          .catchError((error) {
        print(error);
      });
      store.dispatch(CreateDynStockFailAction(error: error));
    });
  }

  if (action is UpdateDynStockAction) {
    DynStocksService()
        .updateDynStock(action.userId, action.dynStockId, action.body)
        .then((response) {
      store.dispatch(UpdateDynStockSuccessAction(dynStock: response));
    }).catchError((error) {
      print(error);
      String emailBodyLine1 = '$error';
      EmailJSService()
          .sendEmail(Email(
              username: 'Myself',
              subject: 'Error while Updating DynStock',
              title:
                  'Error while Updating DynStock for ${action.body.stockCode}',
              subtitle:
                  'The following error resulted while Updating DynStock for ${action.body.stockCode}',
              body: emailBodyLine1))
          .then((value) {})
          .catchError((error) {
        print(error);
      });
      store.dispatch(UpdateDynStockFailAction(error: error));
    });
  }

  if (action is DeleteDynStockAction) {
    DynStock dynStockToBeDeleted =
        store.state.allDynStocks.data.firstWhere((element) {
      return element.dynStockId.uuid == action.dynStockId;
    });
    pauseTransactions[dynStockToBeDeleted.stockCode] = true;
    if (dynStockToBeDeleted.lastTransactionType == 'BUY') {
      // Need to Apply the SELL Logic
      try {
        OrderCategories orderCategories = await KotakStockAPIService()
            .getOrderCategories(action.userId, store.state.accessCode,
                dynStockToBeDeleted.instrumentToken) as OrderCategories;
        // If there is open SELL order, cancel it
        await Future.forEach(orderCategories.OPN, (openOrderId) async {
          await KotakStockAPIService().cancelOrder(
              action.userId, store.state.accessCode, openOrderId as int);
        });
        // orderCategories!.OPN.forEach((openOrderId) async {
        //   await KotakStockAPIService().cancelOrder(
        //       action.userId, store.state.accessCode, openOrderId);
        // });
        bool thereWerePartialOrders = orderCategories.OPF.length > 0;
        await Future.forEach(orderCategories.OPF,
            (partiallyTradedOrderId) async {
          // Modify the existing order to make it fully traded
          int pendingQuantity = await modifyPartialOrdersToFullOrders(
              store,
              action,
              partiallyTradedOrderId as int,
              dynStockToBeDeleted,
              ETransactionType.SELL);
          // Place the SELL order for remaining stocks
          await placeFullOrderAndDeleteDynStock(store, action,
              dynStockToBeDeleted, pendingQuantity, ETransactionType.SELL);
        });
        // orderCategories.OPF.forEach((partiallyTradedOrderId) async {
        //   // Modify the existing order to make it fully traded
        //   int pendingQuantity = await modifyPartialOrdersToFullOrders(
        //       store,
        //       action,
        //       partiallyTradedOrderId,
        //       dynStockToBeDeleted,
        //       ETransactionType.SELL);
        //   // Place the SELL order for remaining stocks
        //   await placeFullOrderAndDeleteDynStock(store, action,
        //       dynStockToBeDeleted, pendingQuantity, ETransactionType.SELL);
        // });
        // If there were no partial orders, then place orders at the market price
        if (!thereWerePartialOrders) {
          await placeFullOrderAndDeleteDynStock(
            store,
            action,
            dynStockToBeDeleted,
            dynStockToBeDeleted.stocksAvailableForTrade,
            ETransactionType.SELL,
          );
        }
      } catch (error) {
        print(error);
        String emailBodyLine1 = '$error';
        pauseTransactions[action.stockCode] = false;
        EmailJSService()
            .sendEmail(Email(
                username: 'Myself',
                subject: 'Error while Deleting DynStock ${action.stockCode}',
                title: 'Error while Deleting DynStock ${action.stockCode}',
                subtitle: 'Error while Deleting DynStock ${action.stockCode}',
                body: emailBodyLine1))
            .then((value) {})
            .catchError((error) {
          print(error);
          store.dispatch(DeleteDynStockFailAction(error: error));
        });
      }
      //////////
      /** 
      KotakStockAPIService()
          .getAllOrderReport(action.userId, store.state.accessCode,
              dynStockToBeDeleted.instrumentToken)
          .then((orderReports) {
        bool partiallyTradedOrderExists = false;
        for (var orderReport in orderReports!.success) {
          if (orderReport.status == EStockTradeStatus.OPN.name) {
            // If there is open SELL order, cancel it
            KotakStockAPIService()
                .cancelOrder(
                    action.userId, store.state.accessCode, orderReport.orderId)
                .then((cancelledOrder) {})
                .catchError((error) {
              pauseTransactions[dynStockToBeDeleted.stockCode] = false;
              print(error);
              pauseTransactions[dynStockToBeDeleted.stockCode] = false;
              String emailBodyLine1 = '$error';
              EmailJSService()
                  .sendEmail(Email(
                      username: 'Myself',
                      subject:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      title:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      subtitle:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      body: emailBodyLine1))
                  .then((value) {})
                  .catchError((error) {
                pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                print(error);
              });
              store.dispatch(DeleteDynStockFailAction(error: error));
            });
          } else if (orderReport.statusInfo == EStockTradeStatus.OPF.name) {
            // Modify the existing order to make it fully traded
            partiallyTradedOrderExists = true;
            int quantitySoldAlready =
                orderReport.orderQuantity - orderReport.pendingQuantity;
            KotakStockAPIService()
                .modifyOrder(
                    action.userId,
                    store.state.accessCode,
                    orderReport.orderId,
                    KotakStockAPIPlaceOrderBody(
                        orderType: 'N',
                        instrumentToken: dynStockToBeDeleted.instrumentToken,
                        transactionType: ETransactionType.SELL.name,
                        quantity: quantitySoldAlready))
                .then((modifiedOrder) {
              bool orderPlacedInNSE =
                  modifiedOrder!.success!.nse != null ? true : false;
              TransactionsService()
                  .createTransaction(
                      action.userId,
                      action.dynStockId,
                      TransactionBody(
                          transactionId: orderPlacedInNSE
                              ? modifiedOrder.success!.nse!.orderId.toString()
                              : modifiedOrder.success!.bse!.orderId.toString(),
                          type: ETransactionType.SELL.name,
                          noOfStocks: quantitySoldAlready,
                          stockCode: action.stockCode,
                          stockPrice: orderReport.price))
                  .then((response) {
                // Place order to SELL the remaining quantity
                // Then place the SELL order to SELL the remaining quantity at the market price
                KotakStockAPIService()
                    .placeOrder(
                        action.userId,
                        store.state.accessCode,
                        KotakStockAPIPlaceOrderBody(
                            orderType: 'N',
                            instrumentToken:
                                dynStockToBeDeleted.instrumentToken,
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
                            dynStockToBeDeleted.instrumentToken)
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
                      if (tradedStock.status == EStockTradeStatus.TRAD.name) {
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
                                    type: ETransactionType.SELL.name,
                                    noOfStocks: orderReport.pendingQuantity,
                                    stockCode: action.stockCode,
                                    stockPrice: tradedStock.price))
                            .then((response) {
                          DynStocksService()
                              .deleteDynStock(action.userId, action.dynStockId)
                              .then((response) {
                            store.dispatch(CreateTransactionSuccessAction(
                                stockCode: dynStockToBeDeleted.stockCode));
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            store.dispatch(DeleteDynStockSuccessAction(
                                dynStockId: response));
                          }).catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                            String emailBodyLine1 = '$error';
                            EmailJSService()
                                .sendEmail(Email(
                                    username: 'Myself',
                                    subject: 'Error while Deleting DynStock',
                                    title:
                                        'Error while Deleting DynStock for ${action.dynStockId}',
                                    subtitle:
                                        'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                                    body: emailBodyLine1))
                                .then((value) {})
                                .catchError((error) {
                              pauseTransactions[dynStockToBeDeleted.stockCode] =
                                  false;
                              pauseTransactions[dynStockToBeDeleted.stockCode] =
                                  false;
                              print(error);
                            });
                            store.dispatch(
                                DeleteDynStockFailAction(error: error));
                          });
                        }).catchError((error) {
                          pauseTransactions[dynStockToBeDeleted.stockCode] =
                              false;
                          pauseTransactions[dynStockToBeDeleted.stockCode] =
                              false;
                          print(error);
                          String emailBodyLine1 = '$error';
                          EmailJSService()
                              .sendEmail(Email(
                                  username: 'Myself',
                                  subject:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  title:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  subtitle:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  body: emailBodyLine1))
                              .then((value) {})
                              .catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                          });
                          store
                              .dispatch(DeleteDynStockFailAction(error: error));
                        });
                      } else {
                        Timer.periodic(Duration(seconds: 5), (timer) {
                          KotakStockAPIService()
                              .getOrderReport(
                                  action.userId,
                                  store.state.accessCode,
                                  (orderPlacedInNSE
                                      ? newOrder.success!.nse!.orderId
                                      : newOrder.success!.bse!.orderId),
                                  dynStockToBeDeleted.instrumentToken)
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
                            if (tradedStock.status ==
                                EStockTradeStatus.TRAD.name) {
                              timer.cancel();
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
                                          type: ETransactionType.SELL.name,
                                          noOfStocks:
                                              orderReport.pendingQuantity,
                                          stockCode: action.stockCode,
                                          stockPrice: tradedStock.price))
                                  .then((response) {
                                DynStocksService()
                                    .deleteDynStock(
                                        action.userId, action.dynStockId)
                                    .then((response) {
                                  store.dispatch(CreateTransactionSuccessAction(
                                      stockCode:
                                          dynStockToBeDeleted.stockCode));
                                  store.dispatch(DeleteDynStockSuccessAction(
                                      dynStockId: response));
                                }).catchError((error) {
                                  pauseTransactions[
                                      dynStockToBeDeleted.stockCode] = false;
                                  pauseTransactions[
                                      dynStockToBeDeleted.stockCode] = false;
                                  print(error);
                                  String emailBodyLine1 = '$error';
                                  EmailJSService()
                                      .sendEmail(Email(
                                          username: 'Myself',
                                          subject:
                                              'Error while Deleting DynStock',
                                          title:
                                              'Error while Deleting DynStock for ${action.dynStockId}',
                                          subtitle:
                                              'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                                          body: emailBodyLine1))
                                      .then((value) {})
                                      .catchError((error) {
                                    pauseTransactions[
                                        dynStockToBeDeleted.stockCode] = false;
                                    pauseTransactions[
                                        dynStockToBeDeleted.stockCode] = false;
                                    print(error);
                                  });
                                  store.dispatch(
                                      DeleteDynStockFailAction(error: error));
                                });
                              }).catchError((error) {
                                pauseTransactions[
                                    dynStockToBeDeleted.stockCode] = false;
                                pauseTransactions[
                                    dynStockToBeDeleted.stockCode] = false;
                                print(error);
                                String emailBodyLine1 = '$error';
                                EmailJSService()
                                    .sendEmail(Email(
                                        username: 'Myself',
                                        subject:
                                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                        title:
                                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                        subtitle:
                                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                        body: emailBodyLine1))
                                    .then((value) {})
                                    .catchError((error) {
                                  pauseTransactions[
                                      dynStockToBeDeleted.stockCode] = false;
                                  print(error);
                                });
                                store.dispatch(
                                    DeleteDynStockFailAction(error: error));
                              });
                            } else if (tradedStock.status ==
                                EStockTradeStatus.CAN.name) {
                              timer.cancel();
                              DynStocksService()
                                  .deleteDynStock(
                                      action.userId, action.dynStockId)
                                  .then((response) {
                                store.dispatch(CreateTransactionSuccessAction(
                                    stockCode: dynStockToBeDeleted.stockCode));
                                store.dispatch(DeleteDynStockSuccessAction(
                                    dynStockId: response));
                              }).catchError((error) {
                                pauseTransactions[
                                    dynStockToBeDeleted.stockCode] = false;
                                print(error);
                                String emailBodyLine1 = '$error';
                                EmailJSService()
                                    .sendEmail(Email(
                                        username: 'Myself',
                                        subject:
                                            'Error while Deleting DynStock',
                                        title:
                                            'Error while Deleting DynStock for ${action.dynStockId}',
                                        subtitle:
                                            'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                                        body: emailBodyLine1))
                                    .then((value) {})
                                    .catchError((error) {
                                  pauseTransactions[
                                      dynStockToBeDeleted.stockCode] = false;
                                  print(error);
                                });
                                store.dispatch(
                                    DeleteDynStockFailAction(error: error));
                              });
                            }
                          }).catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                            String emailBodyLine1 = '$error';
                            EmailJSService()
                                .sendEmail(Email(
                                    username: 'Myself',
                                    subject:
                                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                    title:
                                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                    subtitle:
                                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                    body: emailBodyLine1))
                                .then((value) {})
                                .catchError((error) {
                              pauseTransactions[dynStockToBeDeleted.stockCode] =
                                  false;
                              print(error);
                            });
                            store.dispatch(
                                DeleteDynStockFailAction(error: error));
                          });
                        });
                      }
                    }).catchError((error) {
                      pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                      print(error);
                      String emailBodyLine1 = '$error';
                      EmailJSService()
                          .sendEmail(Email(
                              username: 'Myself',
                              subject:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              title:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              subtitle:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              body: emailBodyLine1))
                          .then((value) {})
                          .catchError((error) {
                        pauseTransactions[dynStockToBeDeleted.stockCode] =
                            false;
                        print(error);
                      });
                      store.dispatch(DeleteDynStockFailAction(error: error));
                    });
                  });
                }).catchError((error) {
                  pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                  print(error);
                  String emailBodyLine1 = '$error';
                  EmailJSService()
                      .sendEmail(Email(
                          username: 'Myself',
                          subject:
                              'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                          title:
                              'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                          subtitle:
                              'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                          body: emailBodyLine1))
                      .then((value) {})
                      .catchError((error) {
                    pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                    print(error);
                  });
                  store.dispatch(DeleteDynStockFailAction(error: error));
                });
              }).catchError((error) {
                pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                print(error);
                String emailBodyLine1 = '$error';
                EmailJSService()
                    .sendEmail(Email(
                        username: 'Myself',
                        subject:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        title:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        subtitle:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        body: emailBodyLine1))
                    .then((value) {})
                    .catchError((error) {
                  pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                  print(error);
                });
                store.dispatch(DeleteDynStockFailAction(error: error));
              });
            }).catchError((error) {
              pauseTransactions[dynStockToBeDeleted.stockCode] = false;
              print(error);
              String emailBodyLine1 = '$error';
              EmailJSService()
                  .sendEmail(Email(
                      username: 'Myself',
                      subject:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      title:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      subtitle:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      body: emailBodyLine1))
                  .then((value) {})
                  .catchError((error) {
                pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                print(error);
              });
              store.dispatch(DeleteDynStockFailAction(error: error));
            });
          }
        }
        if (!partiallyTradedOrderExists) {
          // There are no partial orders, now we need to SELL all the quantity
          KotakStockAPIService()
              .placeOrder(
                  action.userId,
                  store.state.accessCode,
                  KotakStockAPIPlaceOrderBody(
                    orderType: 'N',
                    instrumentToken: dynStockToBeDeleted.instrumentToken,
                    transactionType: ETransactionType.SELL.name,
                    quantity: dynStockToBeDeleted.stocksAvailableForTrade,
                  ))
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
                      dynStockToBeDeleted.instrumentToken)
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
                              type: ETransactionType.SELL.name,
                              noOfStocks:
                                  dynStockToBeDeleted.stocksAvailableForTrade,
                              stockCode: action.stockCode,
                              stockPrice: tradedStock.price))
                      .then((response) {
                    DynStocksService()
                        .deleteDynStock(action.userId, action.dynStockId)
                        .then((response) {
                      store.dispatch(CreateTransactionSuccessAction(
                          stockCode: dynStockToBeDeleted.stockCode));
                      store.dispatch(
                          DeleteDynStockSuccessAction(dynStockId: response));
                    }).catchError((error) {
                      pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                      print(error);
                      String emailBodyLine1 = '$error';
                      EmailJSService()
                          .sendEmail(Email(
                              username: 'Myself',
                              subject: 'Error while Deleting DynStock',
                              title:
                                  'Error while Deleting DynStock for ${action.dynStockId}',
                              subtitle:
                                  'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                              body: emailBodyLine1))
                          .then((value) {})
                          .catchError((error) {
                        pauseTransactions[dynStockToBeDeleted.stockCode] =
                            false;
                        print(error);
                      });
                      store.dispatch(DeleteDynStockFailAction(error: error));
                    });
                  }).catchError((error) {
                    pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                    print(error);
                    String emailBodyLine1 = '$error';
                    EmailJSService()
                        .sendEmail(Email(
                            username: 'Myself',
                            subject:
                                'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                            title:
                                'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                            subtitle:
                                'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                            body: emailBodyLine1))
                        .then((value) {})
                        .catchError((error) {
                      pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                      print(error);
                    });
                    store.dispatch(DeleteDynStockFailAction(error: error));
                  });
                } else {
                  Timer.periodic(Duration(seconds: 5), (timer) {
                    KotakStockAPIService()
                        .getOrderReport(
                            action.userId,
                            store.state.accessCode,
                            (orderPlacedInNSE
                                ? order.success!.nse!.orderId
                                : order.success!.bse!.orderId),
                            dynStockToBeDeleted.instrumentToken)
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
                      if (tradedStock.status == EStockTradeStatus.TRAD.name) {
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
                                    type: ETransactionType.SELL.name,
                                    noOfStocks: dynStockToBeDeleted
                                        .stocksAvailableForTrade,
                                    stockCode: action.stockCode,
                                    stockPrice: tradedStock.price))
                            .then((response) {
                          DynStocksService()
                              .deleteDynStock(action.userId, action.dynStockId)
                              .then((response) {
                            store.dispatch(CreateTransactionSuccessAction(
                                stockCode: dynStockToBeDeleted.stockCode));
                            store.dispatch(DeleteDynStockSuccessAction(
                                dynStockId: response));
                          }).catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                            String emailBodyLine1 = '$error';
                            EmailJSService()
                                .sendEmail(Email(
                                    username: 'Myself',
                                    subject: 'Error while Deleting DynStock',
                                    title:
                                        'Error while Deleting DynStock for ${action.dynStockId}',
                                    subtitle:
                                        'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                                    body: emailBodyLine1))
                                .then((value) {})
                                .catchError((error) {
                              pauseTransactions[dynStockToBeDeleted.stockCode] =
                                  false;
                              print(error);
                            });
                            store.dispatch(
                                DeleteDynStockFailAction(error: error));
                          });
                        }).catchError((error) {
                          pauseTransactions[dynStockToBeDeleted.stockCode] =
                              false;
                          print(error);
                          String emailBodyLine1 = '$error';
                          EmailJSService()
                              .sendEmail(Email(
                                  username: 'Myself',
                                  subject:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  title:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  subtitle:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  body: emailBodyLine1))
                              .then((value) {})
                              .catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                          });
                          store
                              .dispatch(DeleteDynStockFailAction(error: error));
                        });
                      } else if (tradedStock.status ==
                          EStockTradeStatus.CAN.name) {
                        timer.cancel();
                        DynStocksService()
                            .deleteDynStock(action.userId, action.dynStockId)
                            .then((response) {
                          store.dispatch(CreateTransactionSuccessAction(
                              stockCode: dynStockToBeDeleted.stockCode));
                          store.dispatch(DeleteDynStockSuccessAction(
                              dynStockId: response));
                        }).catchError((error) {
                          pauseTransactions[dynStockToBeDeleted.stockCode] =
                              false;
                          print(error);
                          String emailBodyLine1 = '$error';
                          EmailJSService()
                              .sendEmail(Email(
                                  username: 'Myself',
                                  subject: 'Error while Deleting DynStock',
                                  title:
                                      'Error while Deleting DynStock for ${action.dynStockId}',
                                  subtitle:
                                      'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                                  body: emailBodyLine1))
                              .then((value) {})
                              .catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                          });
                          store
                              .dispatch(DeleteDynStockFailAction(error: error));
                        });
                      }
                    }).catchError((error) {
                      pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                      print(error);
                      String emailBodyLine1 = '$error';
                      EmailJSService()
                          .sendEmail(Email(
                              username: 'Myself',
                              subject:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              title:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              subtitle:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              body: emailBodyLine1))
                          .then((value) {})
                          .catchError((error) {
                        pauseTransactions[dynStockToBeDeleted.stockCode] =
                            false;
                        print(error);
                      });
                      store.dispatch(DeleteDynStockFailAction(error: error));
                    });
                  });
                }
              }).catchError((error) {
                pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                print(error);
                String emailBodyLine1 = '$error';
                EmailJSService()
                    .sendEmail(Email(
                        username: 'Myself',
                        subject:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        title:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        subtitle:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        body: emailBodyLine1))
                    .then((value) {})
                    .catchError((error) {
                  pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                  print(error);
                });
                store.dispatch(DeleteDynStockFailAction(error: error));
              });
            });

            ///////
          }).catchError((error) {
            pauseTransactions[dynStockToBeDeleted.stockCode] = false;
            print(error);
            String emailBodyLine1 = '$error';
            EmailJSService()
                .sendEmail(Email(
                    username: 'Myself',
                    subject:
                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                    title:
                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                    subtitle:
                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                    body: emailBodyLine1))
                .then((value) {})
                .catchError((error) {
              pauseTransactions[dynStockToBeDeleted.stockCode] = false;
              print(error);
            });
            store.dispatch(DeleteDynStockFailAction(error: error));
          });
        }
      }).catchError((error) {
        pauseTransactions[dynStockToBeDeleted.stockCode] = false;
        print(error);
      });
      */
    } else if (dynStockToBeDeleted.lastTransactionType == 'SELL') {
      // Need to Apply the BUY Logic
      try {
        KotakStockAPIService()
            .getOrderCategories(action.userId, store.state.accessCode,
                dynStockToBeDeleted.instrumentToken)
            .then((orderCategories) async {
          // If there is open BUY order, cancel it
          await Future.forEach(orderCategories!.OPN, (openOrderId) async {
            await KotakStockAPIService().cancelOrder(
                action.userId, store.state.accessCode, openOrderId as int);
          });
          // orderCategories!.OPN.forEach((openOrderId) async {
          //   await KotakStockAPIService().cancelOrder(
          //       action.userId, store.state.accessCode, openOrderId);
          // });
          bool thereWerePartialOrders = orderCategories.OPF.length > 0;
          await Future.forEach(orderCategories.OPF,
              (partiallyTradedOrderId) async {
            // Modify the existing order to make it fully traded
            int quantityAlreadyBought = await modifyPartialOrdersToFullOrders(
                store,
                action,
                partiallyTradedOrderId as int,
                dynStockToBeDeleted,
                ETransactionType.BUY);
            // Place the SELL order for recently bought stocks in the same order
            await placeFullOrderAndDeleteDynStock(
                store,
                action,
                dynStockToBeDeleted,
                quantityAlreadyBought,
                ETransactionType.SELL);
          });
          // orderCategories.OPF.forEach((partiallyTradedOrderId) async {
          //   // Modify the existing order to make it fully traded
          //   int quantityAlreadyBought = await modifyPartialOrdersToFullOrders(
          //       store,
          //       action,
          //       partiallyTradedOrderId,
          //       dynStockToBeDeleted,
          //       ETransactionType.BUY);
          //   // Place the SELL order for recently bought stocks in the same order
          //   await placeFullOrderAndDeleteDynStock(
          //       store,
          //       action,
          //       dynStockToBeDeleted,
          //       quantityAlreadyBought,
          //       ETransactionType.SELL);
          // });
          // If there were no partial orders, then do nothing
          if (!thereWerePartialOrders) {}
        });
      } catch (error) {
        print(error);
        String emailBodyLine1 = '$error';
        EmailJSService()
            .sendEmail(Email(
                username: 'Myself',
                subject: 'Error while Deleting DynStock ${action.stockCode}',
                title: 'Error while Deleting DynStock ${action.stockCode}',
                subtitle: 'Error while Deleting DynStock ${action.stockCode}',
                body: emailBodyLine1))
            .then((value) {})
            .catchError((error) {
          pauseTransactions[action.stockCode] = false;
          print(error);
          store.dispatch(DeleteDynStockFailAction(error: error));
        });
      }
      ///////////////
      //////////////
      /////////////
      /** 
      KotakStockAPIService()
          .getAllOrderReport(action.userId, store.state.accessCode,
              dynStockToBeDeleted.instrumentToken)
          .then((orderReports) {
        bool partiallyTradedOrderExists = false;
        for (var orderReport in orderReports!.success) {
          if (orderReport.status == EStockTradeStatus.OPN.name) {
            // If there is open BUY order, cancel it
            KotakStockAPIService()
                .cancelOrder(
                    action.userId, store.state.accessCode, orderReport.orderId)
                .then((cancelledOrder) {})
                .catchError((error) {
              pauseTransactions[dynStockToBeDeleted.stockCode] = false;
              print(error);
              String emailBodyLine1 = '$error';
              EmailJSService()
                  .sendEmail(Email(
                      username: 'Myself',
                      subject:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      title:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      subtitle:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      body: emailBodyLine1))
                  .then((value) {})
                  .catchError((error) {
                pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                print(error);
              });
              store.dispatch(DeleteDynStockFailAction(error: error));
            });
          } else if (orderReport.statusInfo == EStockTradeStatus.OPF.name) {
            // Modify the existing order to make it fully traded
            partiallyTradedOrderExists = true;
            int quantityBoughtAlready =
                orderReport.orderQuantity - orderReport.pendingQuantity;
            KotakStockAPIService()
                .modifyOrder(
                    action.userId,
                    store.state.accessCode,
                    orderReport.orderId,
                    KotakStockAPIPlaceOrderBody(
                        orderType: 'N',
                        instrumentToken: dynStockToBeDeleted.instrumentToken,
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
                              ? modifiedOrder.success!.nse!.orderId.toString()
                              : modifiedOrder.success!.bse!.orderId.toString(),
                          type: ETransactionType.BUY.name,
                          noOfStocks: quantityBoughtAlready,
                          stockCode: action.stockCode,
                          stockPrice: orderReport.price))
                  .then((response) {
                // Place order to SELL the already bought quantity above
                KotakStockAPIService()
                    .placeOrder(
                        action.userId,
                        store.state.accessCode,
                        KotakStockAPIPlaceOrderBody(
                            orderType: 'N',
                            instrumentToken:
                                dynStockToBeDeleted.instrumentToken,
                            transactionType: ETransactionType.SELL.name,
                            quantity: quantityBoughtAlready))
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
                            dynStockToBeDeleted.instrumentToken)
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
                      if (tradedStock.status == EStockTradeStatus.TRAD.name) {
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
                                    type: ETransactionType.SELL.name,
                                    noOfStocks: quantityBoughtAlready,
                                    stockCode: action.stockCode,
                                    stockPrice: tradedStock.price))
                            .then((response) {
                          DynStocksService()
                              .deleteDynStock(action.userId, action.dynStockId)
                              .then((response) {
                            store.dispatch(CreateTransactionSuccessAction(
                                stockCode: dynStockToBeDeleted.stockCode));
                            store.dispatch(DeleteDynStockSuccessAction(
                                dynStockId: response));
                          }).catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                            String emailBodyLine1 = '$error';
                            EmailJSService()
                                .sendEmail(Email(
                                    username: 'Myself',
                                    subject: 'Error while Deleting DynStock',
                                    title:
                                        'Error while Deleting DynStock for ${action.dynStockId}',
                                    subtitle:
                                        'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                                    body: emailBodyLine1))
                                .then((value) {})
                                .catchError((error) {
                              pauseTransactions[dynStockToBeDeleted.stockCode] =
                                  false;
                              print(error);
                            });
                            store.dispatch(
                                DeleteDynStockFailAction(error: error));
                          });
                        }).catchError((error) {
                          pauseTransactions[dynStockToBeDeleted.stockCode] =
                              false;
                          print(error);
                          String emailBodyLine1 = '$error';
                          EmailJSService()
                              .sendEmail(Email(
                                  username: 'Myself',
                                  subject:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  title:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  subtitle:
                                      'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                  body: emailBodyLine1))
                              .then((value) {})
                              .catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                          });
                          store
                              .dispatch(DeleteDynStockFailAction(error: error));
                        });
                      } else {
                        Timer.periodic(Duration(seconds: 5), (timer) {
                          KotakStockAPIService()
                              .getOrderReport(
                                  action.userId,
                                  store.state.accessCode,
                                  (orderPlacedInNSE
                                      ? newOrder.success!.nse!.orderId
                                      : newOrder.success!.bse!.orderId),
                                  dynStockToBeDeleted.instrumentToken)
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
                            if (tradedStock.status ==
                                EStockTradeStatus.TRAD.name) {
                              timer.cancel();
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
                                          type: ETransactionType.SELL.name,
                                          noOfStocks:
                                              orderReport.pendingQuantity,
                                          stockCode: action.stockCode,
                                          stockPrice: tradedStock.price))
                                  .then((response) {
                                DynStocksService()
                                    .deleteDynStock(
                                        action.userId, action.dynStockId)
                                    .then((response) {
                                  store.dispatch(CreateTransactionSuccessAction(
                                      stockCode:
                                          dynStockToBeDeleted.stockCode));
                                  store.dispatch(DeleteDynStockSuccessAction(
                                      dynStockId: response));
                                }).catchError((error) {
                                  pauseTransactions[
                                      dynStockToBeDeleted.stockCode] = false;
                                  print(error);
                                  String emailBodyLine1 = '$error';
                                  EmailJSService()
                                      .sendEmail(Email(
                                          username: 'Myself',
                                          subject:
                                              'Error while Deleting DynStock',
                                          title:
                                              'Error while Deleting DynStock for ${action.dynStockId}',
                                          subtitle:
                                              'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                                          body: emailBodyLine1))
                                      .then((value) {})
                                      .catchError((error) {
                                    pauseTransactions[
                                        dynStockToBeDeleted.stockCode] = false;
                                    print(error);
                                  });
                                  store.dispatch(
                                      DeleteDynStockFailAction(error: error));
                                });
                              }).catchError((error) {
                                pauseTransactions[
                                    dynStockToBeDeleted.stockCode] = false;
                                print(error);
                                String emailBodyLine1 = '$error';
                                EmailJSService()
                                    .sendEmail(Email(
                                        username: 'Myself',
                                        subject:
                                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                        title:
                                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                        subtitle:
                                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                        body: emailBodyLine1))
                                    .then((value) {})
                                    .catchError((error) {
                                  pauseTransactions[
                                      dynStockToBeDeleted.stockCode] = false;
                                  print(error);
                                });
                                store.dispatch(
                                    DeleteDynStockFailAction(error: error));
                              });
                            } else if (tradedStock.status ==
                                EStockTradeStatus.CAN.name) {
                              timer.cancel();
                              DynStocksService()
                                  .deleteDynStock(
                                      action.userId, action.dynStockId)
                                  .then((response) {
                                store.dispatch(CreateTransactionSuccessAction(
                                    stockCode: dynStockToBeDeleted.stockCode));
                                store.dispatch(DeleteDynStockSuccessAction(
                                    dynStockId: response));
                              }).catchError((error) {
                                pauseTransactions[
                                    dynStockToBeDeleted.stockCode] = false;
                                print(error);
                                String emailBodyLine1 = '$error';
                                EmailJSService()
                                    .sendEmail(Email(
                                        username: 'Myself',
                                        subject:
                                            'Error while Deleting DynStock',
                                        title:
                                            'Error while Deleting DynStock for ${action.dynStockId}',
                                        subtitle:
                                            'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                                        body: emailBodyLine1))
                                    .then((value) {})
                                    .catchError((error) {
                                  pauseTransactions[
                                      dynStockToBeDeleted.stockCode] = false;
                                  print(error);
                                });
                                store.dispatch(
                                    DeleteDynStockFailAction(error: error));
                              });
                            }
                          }).catchError((error) {
                            pauseTransactions[dynStockToBeDeleted.stockCode] =
                                false;
                            print(error);
                            String emailBodyLine1 = '$error';
                            EmailJSService()
                                .sendEmail(Email(
                                    username: 'Myself',
                                    subject:
                                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                    title:
                                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                    subtitle:
                                        'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                                    body: emailBodyLine1))
                                .then((value) {})
                                .catchError((error) {
                              pauseTransactions[dynStockToBeDeleted.stockCode] =
                                  false;
                              print(error);
                            });
                            store.dispatch(
                                DeleteDynStockFailAction(error: error));
                          });
                        });
                      }
                    }).catchError((error) {
                      pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                      print(error);
                      String emailBodyLine1 = '$error';
                      EmailJSService()
                          .sendEmail(Email(
                              username: 'Myself',
                              subject:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              title:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              subtitle:
                                  'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                              body: emailBodyLine1))
                          .then((value) {})
                          .catchError((error) {
                        pauseTransactions[dynStockToBeDeleted.stockCode] =
                            false;
                        print(error);
                      });
                      store.dispatch(DeleteDynStockFailAction(error: error));
                    });
                  });
                }).catchError((error) {
                  pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                  print(error);
                  String emailBodyLine1 = '$error';
                  EmailJSService()
                      .sendEmail(Email(
                          username: 'Myself',
                          subject:
                              'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                          title:
                              'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                          subtitle:
                              'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                          body: emailBodyLine1))
                      .then((value) {})
                      .catchError((error) {
                    pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                    print(error);
                  });
                  store.dispatch(DeleteDynStockFailAction(error: error));
                });
              }).catchError((error) {
                pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                print(error);
                String emailBodyLine1 = '$error';
                EmailJSService()
                    .sendEmail(Email(
                        username: 'Myself',
                        subject:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        title:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        subtitle:
                            'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                        body: emailBodyLine1))
                    .then((value) {})
                    .catchError((error) {
                  pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                  print(error);
                });
                store.dispatch(DeleteDynStockFailAction(error: error));
              });
            }).catchError((error) {
              pauseTransactions[dynStockToBeDeleted.stockCode] = false;
              print(error);
              String emailBodyLine1 = '$error';
              EmailJSService()
                  .sendEmail(Email(
                      username: 'Myself',
                      subject:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      title:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      subtitle:
                          'Error while creating transaction while Deleting DynStock ${action.stockCode}',
                      body: emailBodyLine1))
                  .then((value) {})
                  .catchError((error) {
                pauseTransactions[dynStockToBeDeleted.stockCode] = false;
                print(error);
              });
              store.dispatch(DeleteDynStockFailAction(error: error));
            });
          }
        }
        if (!partiallyTradedOrderExists) {
          // There are no partial orders, now we need to DELETE the DYNSTOCK
          DynStocksService()
              .deleteDynStock(action.userId, action.dynStockId)
              .then((response) {
            store.dispatch(CreateTransactionSuccessAction(
                stockCode: dynStockToBeDeleted.stockCode));
            store.dispatch(DeleteDynStockSuccessAction(dynStockId: response));
          }).catchError((error) {
            pauseTransactions[dynStockToBeDeleted.stockCode] = false;
            print(error);
            String emailBodyLine1 = '$error';
            EmailJSService()
                .sendEmail(Email(
                    username: 'Myself',
                    subject: 'Error while Deleting DynStock',
                    title:
                        'Error while Deleting DynStock for ${action.dynStockId}',
                    subtitle:
                        'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                    body: emailBodyLine1))
                .then((value) {})
                .catchError((error) {
              pauseTransactions[dynStockToBeDeleted.stockCode] = false;
              print(error);
            });
            store.dispatch(DeleteDynStockFailAction(error: error));
          });
        }
      }).catchError((error) {
        pauseTransactions[dynStockToBeDeleted.stockCode] = false;
        print(error);
      });
      */
    }
    /////////
    ////////
    ////////
    /////
    ////
    ////
    ////
    ////
    ////
    ////
    ////
    ///
  }
  next(action);
}
