import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/state/transactions.state.dart';

TransactionsState transactionsReducer(TransactionsState state, dynamic action) {
  if (action is GetAllTransactionsAction) {
    return TransactionsState.updatedState(
        loading: true, loaded: false, loadFailed: false, data: state.data);
  }
  if (action is GetAllTransactionsSuccessAction) {
    return TransactionsState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: false,
        data: action.data,
        error: null);
  }
  if (action is GetAllTransactionsFailAction) {
    return TransactionsState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: true,
        data: null,
        error: action.error);
  }

  return state;
}
