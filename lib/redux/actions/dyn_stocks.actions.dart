import 'package:dynstocks/models/dyn_stocks.dart';

class GetAllDynStocksAction {
  String userId;
  GetAllDynStocksAction({required this.userId});
}

class GetAllDynStocksSuccessAction {
  final List<DynStock> allDynStocks;
  GetAllDynStocksSuccessAction({required this.allDynStocks});
}

class GetAllDynStocksFailAction {
  final dynamic error;
  GetAllDynStocksFailAction({required this.error});
}

class CreateDynStockAction {
  String userId;
  DynStockBody body;
  double price;
  CreateDynStockAction(
      {required this.userId, required this.price, required this.body});
}

class CreateDynStockSuccessAction {
  DynStock dynStock;
  CreateDynStockSuccessAction({required this.dynStock});
}

class CreateDynStockFailAction {
  final dynamic error;
  CreateDynStockFailAction({required this.error});
}

class UpdateDynStockAction {
  String userId;
  String dynStockId;
  DynStockBody body;
  UpdateDynStockAction(
      {required this.userId, required this.dynStockId, required this.body});
}

class UpdateDynStockSuccessAction {
  DynStock dynStock;
  UpdateDynStockSuccessAction({required this.dynStock});
}

class UpdateDynStockFailAction {
  final dynamic error;
  UpdateDynStockFailAction({required this.error});
}

class DeleteDynStockAction {
  String userId;
  String dynStockId;
  String stockCode;
  DeleteDynStockAction({
    required this.userId,
    required this.dynStockId,
    required this.stockCode,
  });
}

class DeleteDynStockSuccessAction {
  String dynStockId;
  DeleteDynStockSuccessAction({required this.dynStockId});
}

class DeleteDynStockFailAction {
  final dynamic error;
  DeleteDynStockFailAction({required this.error});
}
