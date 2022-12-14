import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/actions/net_returns_for_dyn_stocks.action.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/dyn_stocks.service.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:dynstocks/services/net_returns_for_dyn_stock.service.dart';
import 'package:dynstocks/services/transactions.service.dart';
import 'package:redux/redux.dart';

void netReturnsForDynStockMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetNetReturnsForDynStockAction) {
    NetReturnsForDynStockService()
        .getNetReturnsForDynStock(
            action.userId, action.dynStockId, action.period)
        .then((response) {
      store.dispatch(GetNetReturnsForDynStockSuccessAction(data: response));
    }).catchError((error) {
      store.dispatch(GetNetReturnsForDynStockFailAction(error: error));
    });
  }
  next(action);
}
