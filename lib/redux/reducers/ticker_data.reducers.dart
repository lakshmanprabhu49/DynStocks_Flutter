import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/state/ticker_data.state.dart';

TickerDataState tickerDataReducer(TickerDataState state, dynamic action) {
  if (action is GetAllTickerDataAction) {
    return TickerDataState.updatedState(
        loading: true, loaded: false, loadFailed: false, data: state.data);
  }
  if (action is GetAllTickerDataSuccessAction) {
    return TickerDataState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: false,
        data: action.allTickerData,
        error: null);
  }
  if (action is GetAllTickerDataFailAction) {
    return TickerDataState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: true,
        data: Map(),
        error: action.error);
  }

  return state;
}
