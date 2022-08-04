import 'package:dynstocks/main.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/state/kotak_stock_api.state.dart';

KotakStockAPIState kotakStockAPIReducer(
    KotakStockAPIState state, dynamic action) {
  if (action is KotakStockAPIPlaceOrderAction) {
    return KotakStockAPIState.updatedState(
        placingOrder: true,
        placedOrder: false,
        orderFailed: false,
        loggedIn: state.loggedIn,
        loggingIn: state.loggingIn,
        loginFailed: state.loginFailed,
        jwtToken: state.jwtToken);
  }
  if (action is KotakStockAPIPlaceOrderSuccessAction) {
    return KotakStockAPIState.updatedState(
        placingOrder: false,
        placedOrder: true,
        orderFailed: false,
        data: action.data,
        loggedIn: state.loggedIn,
        loggingIn: state.loggingIn,
        loginFailed: state.loginFailed,
        jwtToken: state.jwtToken);
  }
  if (action is KotakStockAPIPlaceOrderFailAction) {
    return KotakStockAPIState.updatedState(
        placingOrder: false,
        placedOrder: false,
        orderFailed: true,
        data: null,
        error: action.error,
        loggedIn: state.loggedIn,
        loggingIn: state.loggingIn,
        loginFailed: state.loginFailed,
        jwtToken: state.jwtToken);
  }
  if (action is KotakStockAPILoginAction) {
    return KotakStockAPIState.updatedState(
        placingOrder: state.placingOrder,
        placedOrder: state.placedOrder,
        orderFailed: state.orderFailed,
        loggingIn: true,
        loggedIn: false,
        loginFailed: false,
        jwtToken: '');
  }
  if (action is KotakStockAPILoginSuccessAction) {
    return KotakStockAPIState.updatedState(
        placingOrder: state.placingOrder,
        placedOrder: state.placedOrder,
        orderFailed: state.orderFailed,
        data: state.data,
        loggingIn: false,
        loggedIn: true,
        loginFailed: false,
        jwtToken: action.data.token);
  }
  if (action is KotakStockAPILoginFailAction) {
    return KotakStockAPIState.updatedState(
        placingOrder: state.placingOrder,
        placedOrder: state.placedOrder,
        orderFailed: state.orderFailed,
        data: null,
        error: action.error,
        loggingIn: false,
        loggedIn: false,
        loginFailed: true,
        jwtToken: '');
  }
  return state;
}
