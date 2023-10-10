import 'package:dynstocks/redux/actions/dyn_stocks_real_time_price.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/dynstocks_real_time_price.service.dart';
import 'package:redux/redux.dart';

void tickerDataMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetDynStocksRealTimePriceAction) {
    DynStocksRealTimePriceService()
        .getRealTimePrice(action.userId)
        .then((response) {
      store.dispatch(GetDynStocksRealTimePriceSuccessAction(data: response));
    });
  }
  if (action is UpdateDynStocksRealTimePriceAction) {
    DynStocksRealTimePriceService()
        .putRealTimePrice(action.userId, action.stockDetails)
        .then((response) {
      store.dispatch(UpdateDynStocksRealTimePriceSuccessAction(data: response));
    });
  }
  next(action);
}
