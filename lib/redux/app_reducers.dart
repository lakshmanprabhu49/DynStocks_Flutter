import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/redux/reducers/authentication.reducers.dart';
import 'package:dynstocks/redux/reducers/dyn_stocks.reducers.dart';
import 'package:dynstocks/redux/reducers/kotak_stock_api.reducers.dart';
import 'package:dynstocks/redux/reducers/local_user_creds.reducers.dart';
import 'package:dynstocks/redux/reducers/net_returns_for_dyn_stock.reducers.dart';
import 'package:dynstocks/redux/reducers/transactions.reducers.dart';
import 'package:dynstocks/redux/reducers/ticker_data.reducers.dart';
import 'package:dynstocks/redux/reducers/user_info.reducers.dart';

AppState appReducer(AppState state, dynamic action) {
  if (state.authState.loggedOut) {
    return AppState.initialState();
  } else {
    return AppState.updatedState(
        userId: userIdReducer(state.userId, action),
        accessCode: accessCodeReducer(state.accessCode, action),
        allTransactions: transactionsReducer(state.allTransactions, action),
        allDynStocks: dynStocksReducer(state.allDynStocks, action),
        allTickerData: tickerDataReducer(state.allTickerData, action),
        kotakStockAPI: kotakStockAPIReducer(state.kotakStockAPI, action),
        authState: authReducer(state.authState, action),
        netReturnsForDynStock:
            netReturnsForDynStockReducer(state.netReturnsForDynStock, action),
        userInfo: userInfoReducer(state.userInfo, action));
  }
}
