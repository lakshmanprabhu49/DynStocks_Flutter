import 'package:dynstocks/models/dyn_stocks_real_time_price.dart';

class GetDynStocksRealTimePriceAction {
  String userId;
  GetDynStocksRealTimePriceAction({required this.userId});
}

class GetDynStocksRealTimePriceSuccessAction {
  DynStocksRealTimePrice data;
  GetDynStocksRealTimePriceSuccessAction({required this.data});
}

class UpdateDynStocksRealTimePriceAction {
  String userId;
  List<StockDetail> stockDetails;
  UpdateDynStocksRealTimePriceAction(
      {required this.userId, required this.stockDetails});
}

class UpdateDynStocksRealTimePriceSuccessAction {
  DynStocksRealTimePrice data;
  UpdateDynStocksRealTimePriceSuccessAction({required this.data});
}
