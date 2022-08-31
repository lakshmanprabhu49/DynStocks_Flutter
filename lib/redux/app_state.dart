import 'package:dynstocks/models/local_user_creds.dart';
import 'package:dynstocks/redux/state/authentication.state.dart';
import 'package:dynstocks/redux/state/dyn_stocks.state.dart';
import 'package:dynstocks/redux/state/transactions_create.state.dart';
import 'package:dynstocks/redux/state/kotak_stock_api.state.dart';
import 'package:dynstocks/redux/state/net_returns_for_dyn_stock.state.dart';
import 'package:dynstocks/redux/state/transactions.state.dart';
import 'package:dynstocks/redux/state/ticker_data.state.dart';
import 'package:dynstocks/redux/state/user_info.state.dart';

class AppState {
  String userId = '';
  String accessCode = '';
  NetReturnsForDynStockState netReturnsForDynStock =
      NetReturnsForDynStockState.initialState();
  String DYNSTOCKS_X_REQUEST_ID = 'DYNSTOCKS_X_REQUEST_ID';
  TransactionsState allTransactions = TransactionsState.initialState();
  DynStocksState allDynStocks = DynStocksState.initialState();
  TransactionsCreateState transactionsCreateState =
      TransactionsCreateState.initialState();
  TickerDataState allTickerData = TickerDataState.initialState();
  KotakStockAPIState kotakStockAPI = KotakStockAPIState.initialState();
  UserInfoState userInfo = UserInfoState.initialState();
  AuthState authState = AuthState.initialState();
  AppState.initialState() {
    userId = '';
    accessCode = '';
    allTransactions = TransactionsState.initialState();
    allDynStocks = DynStocksState.initialState();
    allTickerData = TickerDataState.initialState();
    kotakStockAPI = KotakStockAPIState.initialState();
    userInfo = UserInfoState.initialState();
    authState = AuthState.initialState();
    netReturnsForDynStock = NetReturnsForDynStockState.initialState();
    transactionsCreateState = TransactionsCreateState.initialState();
  }
  AppState.updatedState(
      {TransactionsState? allTransactions,
      DynStocksState? allDynStocks,
      TickerDataState? allTickerData,
      String? accessCode,
      KotakStockAPIState? kotakStockAPI,
      UserInfoState? userInfo,
      AuthState? authState,
      String? userId,
      NetReturnsForDynStockState? netReturnsForDynStock,
      TransactionsCreateState? transactionsCreateState}) {
    if (allDynStocks != null) {
      this.allDynStocks = allDynStocks;
    }
    if (allTransactions != null) {
      this.allTransactions = allTransactions;
    }
    if (allTickerData != null) {
      this.allTickerData = allTickerData;
    }
    if (accessCode != null) {
      this.accessCode = accessCode;
    }
    if (kotakStockAPI != null) {
      this.kotakStockAPI = kotakStockAPI;
    }
    if (userInfo != null) {
      this.userInfo = userInfo;
    }
    if (authState != null) {
      this.authState = authState;
    }
    if (userId != null) {
      this.userId = userId;
    }
    if (netReturnsForDynStock != null) {
      this.netReturnsForDynStock = netReturnsForDynStock;
    }
    if (transactionsCreateState != null) {
      this.transactionsCreateState = transactionsCreateState;
    }
  }
}
