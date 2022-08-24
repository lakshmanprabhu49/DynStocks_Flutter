import 'package:dynstocks/models/dyn_stocks.dart';

class DynStocksState {
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  bool creating = false;
  bool created = false;
  bool createFailed = false;
  bool updating = false;
  bool updated = false;
  bool updateFailed = false;
  bool deleting = false;
  bool deleted = false;
  bool deleteFailed = false;
  List<DynStock> data = List.empty();
  dynamic error;

  DynStocksState.initialState() {
    loading = false;
    loaded = false;
    loadFailed = false;
    creating = false;
    created = false;
    createFailed = false;
    updating = false;
    updated = false;
    updateFailed = false;
    deleting = false;
    deleted = false;
    deleteFailed = false;
    data = List.empty();
    error = null;
  }

  DynStocksState.updatedState(
      {required this.loading,
      required this.loaded,
      required this.loadFailed,
      required this.creating,
      required this.created,
      required this.createFailed,
      required this.updating,
      required this.updated,
      required this.updateFailed,
      required this.deleting,
      required this.deleted,
      required this.deleteFailed,
      required this.data,
      this.error}) {}
}
