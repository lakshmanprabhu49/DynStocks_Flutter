import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/state/transactions.state.dart';

TransactionsState transactionsReducer(TransactionsState state, dynamic action) {
  if (action is GetAllTransactionsAction) {
    return TransactionsState.updatedState(
        loading: true,
        loaded: false,
        loadFailed: false,
        creating: state.creating,
        created: state.created,
        createFailed: state.createFailed,
        data: state.data);
  }
  if (action is GetAllTransactionsSuccessAction) {
    return TransactionsState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: false,
        creating: state.creating,
        created: state.created,
        createFailed: state.createFailed,
        data: action.data,
        error: null);
  }
  if (action is GetAllTransactionsFailAction) {
    return TransactionsState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: true,
        creating: state.creating,
        created: state.created,
        createFailed: state.createFailed,
        data: null,
        error: action.error);
  }

  if (action is CreateTransactionAction) {
    return TransactionsState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: state.loadFailed,
        creating: true,
        created: false,
        createFailed: false,
        data: state.data);
  }
  if (action is CreateTransactionSuccessAction) {
    state.data?.items.add(action.transaction);
    return TransactionsState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: state.loadFailed,
        creating: false,
        created: true,
        createFailed: false,
        data: state.data,
        error: null);
  }
  if (action is CreateTransactionFailAction) {
    return TransactionsState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: state.loadFailed,
        creating: false,
        created: false,
        createFailed: true,
        data: null,
        error: action.error);
  }

  return state;
}
