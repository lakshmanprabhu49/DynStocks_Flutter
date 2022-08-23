import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
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
            dynStockId: action.dynStockId)
        .then((response) {
      store.dispatch(GetAllTransactionsSuccessAction(data: response));
    }).catchError((error) {
      store.dispatch(GetAllTransactionsFailAction(error: error));
    });
  }
  if (action is CreateTransactionAction) {
    DynStock dynStockInvolved =
        store.state.allDynStocks.data.firstWhere((element) {
      return element.dynStockId.uuid == action.dynStockId;
    });
    KotakStockAPIService()
        .placeOrder(
            action.userId,
            store.state.accessCode,
            KotakStockAPIPlaceOrderBody(
                orderType: 'N',
                instrumentToken: action.instrumentToken,
                transactionType: action.body.type,
                quantity: action.body.noOfStocks))
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
                CreateTransactionSuccessAction(transaction: response));
            DateTime transactionTime = DateTime.fromMillisecondsSinceEpoch(
                response.transactionTime.date);
            String emailBodyLine1 =
                'Transaction Type: ${response.type}, Transaction Price: ${response.stockPrice}, Number of Stocks: ${response.noOfStocks}';
            String emailBodyLine2 =
                'Transaction Time: ${transactionTime.hour}:${transactionTime.minute}:${transactionTime.second} ${transactionTime.day}/${transactionTime.month}/${transactionTime.year}';
            String emailBodyLine3 = 'Total Amount: ${response.amount}';
            EmailJSService()
                .sendEmail(Email(
                    username: 'Myself',
                    subject: 'Transaction Made',
                    title: 'Transaction Made for ${action.body.stockCode}',
                    subtitle:
                        'Transaction has been made for ${action.body.stockCode} with the following params',
                    body:
                        '${emailBodyLine1} ${emailBodyLine2} ${emailBodyLine3}'))
                .then((value) {
              store.dispatch(GetAllDynStocksAction(userId: action.userId));
            }).catchError((error) {
              store.dispatch(CreateTransactionFailAction(error: error));
            });
          }).catchError((error) {
            store.dispatch(CreateTransactionFailAction(error: error));
          });
        }).catchError((error) {
          store.dispatch(CreateTransactionFailAction(error: error));
        });
      });
    }).catchError((error) {
      store.dispatch(CreateTransactionFailAction(error: error));
    });
  }
  next(action);
}
