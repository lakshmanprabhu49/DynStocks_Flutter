import 'package:dynstocks/models/kotak_stock_api.dart';

class KotakStockAPIState {
  bool placingOrder = false;
  bool placedOrder = false;
  bool orderFailed = false;
  bool loggingIn = false;
  bool loggedIn = false;
  bool loginFailed = false;
  String jwtToken = '';
  KotakStockApiPlaceOrderResponse? data;
  dynamic error;

  KotakStockAPIState.initialState() {
    placingOrder = false;
    placedOrder = false;
    orderFailed = false;
    loggingIn = false;
    loggedIn = false;
    loginFailed = false;
    jwtToken = '';
    data = null;
  }

  KotakStockAPIState.updatedState(
      {required this.placingOrder,
      required this.placedOrder,
      required this.orderFailed,
      this.data,
      required this.loggingIn,
      required this.loggedIn,
      required this.loginFailed,
      required this.jwtToken,
      this.error});
}
