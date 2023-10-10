import 'package:dynstocks/redux/actions/dyn_stocks_real_time_price.actions.dart';
import 'package:dynstocks/redux/state/dyn_stocks_real_time_price.state.dart';

DynStocksRealTimePriceState dynStocksReducer(
    DynStocksRealTimePriceState state, dynamic action) {
  if (action is GetDynStocksRealTimePriceAction) {
    return DynStocksRealTimePriceState.updatedState(
        loading: true,
        loaded: false,
        loadFailed: false,
        updating: state.updating,
        updated: state.updated,
        updateFailed: state.updateFailed,
        data: state.data);
  }
  if (action is GetDynStocksRealTimePriceSuccessAction) {
    return DynStocksRealTimePriceState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: false,
        updating: state.updating,
        updated: state.updated,
        updateFailed: state.updateFailed,
        data: action.data.stockDetails);
  }

  if (action is UpdateDynStocksRealTimePriceAction) {
    return DynStocksRealTimePriceState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: state.loadFailed,
        updating: true,
        updated: false,
        updateFailed: false,
        data: state.data);
  }
  if (action is UpdateDynStocksRealTimePriceSuccessAction) {
    return DynStocksRealTimePriceState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: state.loadFailed,
        updating: false,
        updated: true,
        updateFailed: false,
        data: action.data.stockDetails);
  }
  return state;
}
