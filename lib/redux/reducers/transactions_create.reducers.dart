import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/state/transactions_create.state.dart';

TransactionsCreateState transactionsCreateReducer(
    TransactionsCreateState state, dynamic action) {
  if (action is CreateTransactionAction) {
    state.data[action.stockCode] = TransactionsCreate(
        creating: true, created: false, createFailed: false, error: null);
    return TransactionsCreateState.updatedState(data: state.data, error: null);
  }
  if (action is CreateTransactionSuccessAction) {
    state.data[action.stockCode] = TransactionsCreate(
        creating: false, created: true, createFailed: false, error: null);
    return TransactionsCreateState.updatedState(data: state.data, error: null);
  }
  if (action is CreateTransactionFailAction) {
    state.data[action.stockCode] =
        TransactionsCreate(creating: false, created: false, createFailed: true);
    return TransactionsCreateState.updatedState(
        data: state.data, error: action.error);
  }
  if (action is InitializeCreateTransactionStateAction) {
    return TransactionsCreateState.updatedState(data: action.data);
  }

  return state;
}
