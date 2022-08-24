class GetNetReturnsForDynStockAction {
  String userId;
  String dynStockId;
  String period;
  GetNetReturnsForDynStockAction(
      {required this.userId, required this.dynStockId, required this.period});
}

class GetNetReturnsForDynStockSuccessAction {
  final double data;
  GetNetReturnsForDynStockSuccessAction({required this.data});
}

class GetNetReturnsForDynStockFailAction {
  final dynamic error;
  GetNetReturnsForDynStockFailAction({required this.error});
}
