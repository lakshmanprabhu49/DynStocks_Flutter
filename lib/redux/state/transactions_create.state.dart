import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/transactions.dart';

class TransactionsCreateState {
  Map<String, TransactionsCreate> data = <String, TransactionsCreate>{};
  dynamic error;
  TransactionsCreateState.initialState() {
    data = <String, TransactionsCreate>{};
    error = null;
  }
  TransactionsCreateState.updatedState({required this.data, this.error});
}
