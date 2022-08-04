import 'package:dynstocks/models/kotak_stock_api.dart';

class KotakStockAPIPlaceOrderAction {
  String userId;
  String dynStockId;
  String stockCode;
  String accessCode;
  KotakStockAPIPlaceOrderBody body;
  KotakStockAPIPlaceOrderAction(
      {required this.userId,
      required this.accessCode,
      required this.dynStockId,
      required this.stockCode,
      required this.body});
}

class KotakStockAPIPlaceOrderSuccessAction {
  final KotakStockApiPlaceOrderResponse data;
  KotakStockAPIPlaceOrderSuccessAction({required this.data});
}

class KotakStockAPIPlaceOrderFailAction {
  final dynamic error;
  KotakStockAPIPlaceOrderFailAction({required this.error});
}

class KotakStockAPILoginAction {
  String accessCode;
  KotakStockAPILoginAction({required this.accessCode});
}

class KotakStockAPILoginSuccessAction {
  KotakStockApiLoginResponse data;
  KotakStockAPILoginSuccessAction({required this.data});
}

class KotakStockAPILoginFailAction {
  final dynamic error;
  KotakStockAPILoginFailAction({required this.error});
}
