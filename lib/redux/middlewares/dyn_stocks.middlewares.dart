import 'dart:async';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/dyn_stocks.service.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:dynstocks/services/transactions.service.dart';
import 'package:redux/redux.dart';

void dynStocksMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetAllDynStocksAction) {
    DynStocksService().getDynStocks(action.userId).then((response) {
      store.dispatch(GetAllDynStocksSuccessAction(allDynStocks: response));
      Map<String, TransactionsCreate> map =
          Map<String, TransactionsCreate>.from(
              store.state.transactionsCreateState.data);
      bool mapAltered = false;
      for (DynStock dynStock in response) {
        if (map[dynStock.stockCode] == null) {
          mapAltered = true;
          map[dynStock.stockCode] = TransactionsCreate(
              creating: false, created: false, createFailed: false);
        }
      }
      if (mapAltered) {
        store.dispatch(InitializeCreateTransactionStateAction(data: map));
      }
    }).catchError((error) {
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
          .catchError((error) {});
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
                  .catchError((error) {});
              store.dispatch(CreateDynStockFailAction(error: error));
            });
          }).catchError((error) {
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
                .catchError((error) {});
            store.dispatch(CreateDynStockFailAction(error: error));
          });
        });
      },
    ).catchError((error) {
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
          .catchError((error) {});
      store.dispatch(CreateDynStockFailAction(error: error));
    });
  }

  if (action is UpdateDynStockAction) {
    DynStocksService()
        .updateDynStock(action.userId, action.dynStockId, action.body)
        .then((response) {
      store.dispatch(UpdateDynStockSuccessAction(dynStock: response));
    }).catchError((error) {
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
          .catchError((error) {});
      store.dispatch(UpdateDynStockFailAction(error: error));
    });
  }

  if (action is DeleteDynStockAction) {
    DynStock dynStockToBeDeleted =
        store.state.allDynStocks.data.firstWhere((element) {
      return element.dynStockId.uuid == action.dynStockId;
    });

    if (dynStockToBeDeleted.lastTransactionType == 'BUY') {
      // Last executed order was BUY, so we need to sell the stocks before deleting the dynstocks
      KotakStockAPIService()
          .placeOrder(
        action.userId,
        appStore.state.accessCode,
        KotakStockAPIPlaceOrderBody(
            orderType: 'N',
            instrumentToken: dynStockToBeDeleted.instrumentToken,
            transactionType: 'SELL',
            quantity: dynStockToBeDeleted.stocksAvailableForTrade),
      )
          .then((order) {
        bool orderPlacedInNSE = order!.success!.nse != null ? true : false;
        Future.delayed(Duration(milliseconds: 200), () {
          KotakStockAPIService()
              .getOrderReport(
                  action.userId,
                  appStore.state.accessCode,
                  (orderPlacedInNSE
                      ? order.success!.nse!.orderId
                      : order.success!.bse!.orderId),
                  dynStockToBeDeleted.instrumentToken)
              .then((orderReport) {
            TransactionsService()
                .createTransaction(
                    action.userId,
                    action.dynStockId,
                    TransactionBody(
                        transactionId: orderPlacedInNSE
                            ? order.success!.nse!.orderId.toString()
                            : order.success!.bse!.orderId.toString(),
                        type: 'SELL',
                        noOfStocks: dynStockToBeDeleted.stocksAvailableForTrade,
                        stockCode: dynStockToBeDeleted.stockCode,
                        stockPrice: orderReport!.success
                            .firstWhere((element) =>
                                element.orderId ==
                                (orderPlacedInNSE
                                    ? order.success!.nse!.orderId
                                    : order.success!.bse!.orderId))
                            .price))
                .then((transaction) {
              DynStocksService()
                  .deleteDynStock(action.userId, action.dynStockId)
                  .then((response) {
                store.dispatch(
                    DeleteDynStockSuccessAction(dynStockId: response));
              }).catchError((error) {
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
                    .catchError((error) {});
                store.dispatch(DeleteDynStockFailAction(error: error));
              });
            }).catchError((error) {
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
                  .catchError((error) {});
              store.dispatch(DeleteDynStockFailAction(error: error));
            });
          });
        });
      });
    } else {
      DynStocksService()
          .deleteDynStock(action.userId, action.dynStockId)
          .then((response) {
        store.dispatch(DeleteDynStockSuccessAction(dynStockId: response));
      }).catchError((error) {
        String emailBodyLine1 = '$error';
        EmailJSService()
            .sendEmail(Email(
                username: 'Myself',
                subject: 'Error while Deleting DynStock',
                title: 'Error while Deleting DynStock for ${action.dynStockId}',
                subtitle:
                    'The following error resulted while Creating DynStock for for ${action.dynStockId}',
                body: emailBodyLine1))
            .then((value) {})
            .catchError((error) {});
        store.dispatch(DeleteDynStockFailAction(error: error));
      });
    }
  }
  next(action);
}
