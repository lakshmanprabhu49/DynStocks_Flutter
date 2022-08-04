import 'package:dynstocks/models/transactions.dart';

class TransactionsState {
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  bool creating = false;
  bool created = false;
  bool createFailed = false;
  List<Transaction> data = List.empty(growable: true);
  dynamic error;

  TransactionsState.initialState() {
    loading = false;
    loaded = false;
    loadFailed = false;
    creating = false;
    created = false;
    createFailed = false;
    data = List.empty(growable: true);
    error = null;
  }

  TransactionsState.updatedState(
      {required this.loading,
      required this.loaded,
      required this.loadFailed,
      required this.creating,
      required this.created,
      required this.createFailed,
      required this.data,
      this.error});
}
