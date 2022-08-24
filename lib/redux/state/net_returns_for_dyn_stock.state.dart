class NetReturnsForDynStockState {
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  double data = 0.0;
  dynamic error;
  NetReturnsForDynStockState.initialState() {
    loaded = false;
    loading = false;
    loadFailed = false;
    data = 0.0;
    error = null;
  }

  NetReturnsForDynStockState.updatedState({
    required this.loading,
    required this.loaded,
    required this.loadFailed,
    this.data = 0.0,
    this.error,
  });
}
