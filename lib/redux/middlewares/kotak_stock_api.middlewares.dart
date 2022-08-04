import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
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
      print('Kotak API ERROR: ${error.toString()}');
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
      store.dispatch(KotakStockAPILoginFailAction(error: error));
    });
  }
  next(action);
}
