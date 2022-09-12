import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/gmail_error_message.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

class PostMarketTimer {
  static Timer? timer;
  static BuildContext? context;
  static Future<void> startPostMarketTimer(BuildContext context) async {
    context = context;
    DateTime startingTime = DateTime.now();
    if (startingTime.hour > 15 ||
        (startingTime.hour == 15 && startingTime.minute > 30)) {
      return;
    }
    timer ??= Timer.periodic(Duration(seconds: 1), (timer) async {
      DateTime now = DateTime.now();
      if (now.hour > 15 || (now.hour == 15 && now.minute > 30)) {
        timer.cancel();
        // Need to get orders and check if there are partial orders
        for (var dynStock in appStore.state.allDynStocks.data) {
          appStore.state.transactionsCreateState.data[dynStock.stockCode] =
              TransactionsCreate(
                  creating: false, created: false, createFailed: false);
          StoreProvider.of<AppState>(context).dispatch(
              InitializeCreateTransactionStateAction(
                  data: appStore.state.transactionsCreateState.data));
          KotakStockAPIService()
              .getAllOrderReport(appStore.state.userId,
                  appStore.state.accessCode, dynStock.instrumentToken)
              .then((orderReports) async {
            for (var orderReport in orderReports!.success) {
              if (orderReport.statusInfo == EStockTradeStatus.OPF.name) {
                if (orderReport.transactionType == ETransactionType.BUY.name) {
                  int A =
                      orderReport.orderQuantity; // Total Quantity to be bought
                  int B = orderReport.orderQuantity -
                      orderReport.pendingQuantity; // Actual Quantity bought
                  StoreProvider.of<AppState>(context).dispatch(
                      CreateTransactionAction(
                          userId: appStore.state.userId,
                          instrumentToken:
                              orderReport.instrumentToken.toString(),
                          dynStockId: dynStock.dynStockId.uuid,
                          stockCode: dynStock.stockCode,
                          body: TransactionBody(
                            transactionId:
                                DateTime.now().microsecond.toString(),
                            type: ETransactionType.BUY.name,
                            noOfStocks: B,
                            stockCode: dynStock.stockCode,
                            stockPrice: orderReport.price,
                            stocksAvailableForTrade: B,
                          ),
                          stockOrderType: EStockOrderType.Market.name,
                          placeKotakAPIStockOrder: false));
                } else if (orderReport.transactionType ==
                    ETransactionType.SELL.name) {
                  int A = orderReport
                      .orderQuantity; // Total Quantity supposed to be sold
                  int B = orderReport.orderQuantity -
                      orderReport.pendingQuantity; // Actual Quantity sold
                  StoreProvider.of<AppState>(context).dispatch(
                      CreateTransactionAction(
                          userId: appStore.state.userId,
                          instrumentToken:
                              orderReport.instrumentToken.toString(),
                          dynStockId: dynStock.dynStockId.uuid,
                          stockCode: dynStock.stockCode,
                          body: TransactionBody(
                            transactionId:
                                DateTime.now().microsecond.toString(),
                            type: ETransactionType.SELL.name,
                            noOfStocks: B,
                            stockCode: dynStock.stockCode,
                            stockPrice: orderReport.price,
                            stocksAvailableForTrade: A - B,
                          ),
                          stockOrderType: EStockOrderType.Market.name,
                          placeKotakAPIStockOrder: false));
                }
              }
            }
          }).catchError((error) {
            print(error);
            String emailBodyLine1 = '$error';
            GmailErrorMessageService()
                .sendEmail(
                    'Error while creating POST market transaction for DynStock ${dynStock.stockCode}',
                    '<h2>Error while creating POST market transaction for DynStock ${dynStock.stockCode} for user ${appStore.state.username}</h2><br/><p>${emailBodyLine1}</p>')
                .then((value) {})
                .catchError((error) {
              print(error);
            });
            // EmailJSService()
            //     .sendEmail(Email(
            //         username: 'Myself',
            //         subject:
            //             'Error while creating POST market transaction for DynStock ${dynStock.stockCode}',
            //         title:
            //             'Error while creating POST market transaction for DynStock ${dynStock.stockCode}',
            //         subtitle:
            //             'Error while creating POST market transaction for DynStock ${dynStock.stockCode}',
            //         body: emailBodyLine1))
            //     .then((value) {})
            //     .catchError((error) {
            //   print(error);
            // });
          });
        }
      }
    });
  }

  static bool stopPostMarketTimer() {
    if (timer != null) {
      timer?.cancel();
    }
    return true;
  }
}
