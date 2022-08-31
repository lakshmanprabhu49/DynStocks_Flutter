import 'package:dynstocks/models/transactions.dart';

class TransactionsState {
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  TransactionsResponse? data;
  dynamic error;

  TransactionsState.initialState() {
    loading = false;
    loaded = false;
    loadFailed = false;
    data = null;
    error = null;
  }

  TransactionsState.updatedState(
      {required this.loading,
      required this.loaded,
      required this.loadFailed,
      required this.data,
      this.error});
}
