import 'package:dynstocks/models/yahoo_finance_data.dart';

class TickerDataState {
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  Map<String, TickerData> data = Map();
  dynamic error;

  TickerDataState.initialState() {
    loading = false;
    loaded = false;
    loadFailed = false;
    data = Map();
    error = null;
  }

  TickerDataState.updatedState(
      {required this.loading,
      required this.loaded,
      required this.loadFailed,
      required this.data,
      this.error});
}
