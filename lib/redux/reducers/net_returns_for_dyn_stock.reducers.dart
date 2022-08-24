import 'package:dynstocks/redux/actions/net_returns_for_dyn_stocks.action.dart';
import 'package:dynstocks/redux/state/net_returns_for_dyn_stock.state.dart';

NetReturnsForDynStockState netReturnsForDynStockReducer(
    NetReturnsForDynStockState state, dynamic action) {
  if (action is GetNetReturnsForDynStockAction) {
    return NetReturnsForDynStockState.updatedState(
        loading: true, loaded: false, loadFailed: false);
  }
  if (action is GetNetReturnsForDynStockSuccessAction) {
    return NetReturnsForDynStockState.updatedState(
        loading: false, loaded: true, loadFailed: false, data: action.data);
  }
  if (action is GetNetReturnsForDynStockFailAction) {
    return NetReturnsForDynStockState.updatedState(
        loading: false,
        loaded: false,
        loadFailed: true,
        data: 0.0,
        error: action.error);
  }
  return state;
}
