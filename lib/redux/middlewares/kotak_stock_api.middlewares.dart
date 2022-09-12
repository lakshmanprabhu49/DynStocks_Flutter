import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/gmail_error_message.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:redux/redux.dart';

void kotakStockAPIMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is KotakStockAPIPlaceOrderAction) {
    KotakStockAPIService()
        .placeOrder(action.userId, action.accessCode, action.body)
        .then((response) {
      store.dispatch(KotakStockAPIPlaceOrderSuccessAction(
          data: response as KotakStockApiPlaceOrderResponse));
      bool transactionHappenedInNSE =
          (response.success?.nse != null ? true : false);
    }).catchError((error) {
      print(error);
      String emailBodyLine1 = '$error';
      GmailErrorMessageService()
          .sendEmail(
              'Error while Placing Order for DynStock ${action.stockCode}',
              '<h5>The following error resulted while Placing Order for DynStock ${action.stockCode} for user ${store.state.username}</h5><br/><p>${emailBodyLine1}</p>')
          .then((value) {})
          .catchError((error) {
        print(error);
      });
      // EmailJSService()
      //     .sendEmail(Email(
      //         username: 'Myself',
      //         subject:
      //             'Error while Placing Order for DynStock ${action.stockCode}',
      //         title:
      //             'Error while Placing Order for DynStock ${action.stockCode}',
      //         subtitle:
      //             'The following error resulted while Placing Order for DynStock ${action.stockCode}',
      //         body: emailBodyLine1))
      //     .then((value) {})
      //     .catchError((error) {
      //   print(error);
      // });
      store.dispatch(KotakStockAPIPlaceOrderFailAction(error: error));
    });
  }
  if (action is KotakStockAPILoginAction) {
    KotakStockAPIService()
        .login(appStore.state.userId, action.accessCode)
        .then((response) {
      store.dispatch(KotakStockAPILoginSuccessAction(
          data: response as KotakStockApiLoginResponse));
    }).catchError((error) {
      print(error);
      String emailBodyLine1 = '$error';
      GmailErrorMessageService()
          .sendEmail('Error while Logging in for KOTAK STOCK API',
              '<h5>Error while Logging in for KOTAK STOCK API for user ${store.state.username}</h5><br/><p>${emailBodyLine1}</p>')
          .then((value) {})
          .catchError((error) {
        print(error);
      });
      // EmailJSService()
      //     .sendEmail(Email(
      //         username: 'Myself',
      //         subject: 'Error while Logging in for KOTAK STOCK API',
      //         title: 'Error while Logging in for KOTAK STOCK API',
      //         subtitle:
      //             'The following error resulted while Logging in for KOTAK STOCK API',
      //         body: emailBodyLine1))
      //     .then((value) {})
      //     .catchError((error) {
      //   print(error);
      // });
      store.dispatch(KotakStockAPILoginFailAction(error: error));
    });
  }
  next(action);
}
