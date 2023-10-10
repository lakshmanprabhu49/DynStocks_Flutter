import 'package:dynstocks/models/dyn_stocks_real_time_price.dart';

class DynStocksRealTimePriceState {
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  bool updating = false;
  bool updated = false;
  bool updateFailed = false;
  List<StockDetail> data = List.empty();
  dynamic error;

  DynStocksRealTimePriceState.initialState() {
    loading = false;
    loaded = false;
    loadFailed = false;
    updating = false;
    updated = false;
    updateFailed = false;
    data = List.empty();
    error = null;
  }

  DynStocksRealTimePriceState.updatedState(
      {required this.loading,
      required this.loaded,
      required this.loadFailed,
      required this.updating,
      required this.updated,
      required this.updateFailed,
      required this.data,
      this.error}) {}
}
