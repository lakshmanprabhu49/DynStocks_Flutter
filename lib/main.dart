import 'dart:async';
import 'dart:io';

import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/app_reducers.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/redux/middlewares/authentication.middlewares.dart';
import 'package:dynstocks/redux/middlewares/dyn_stocks.middlewares.dart';
import 'package:dynstocks/redux/middlewares/kotak_stock_api.middlewares.dart';
import 'package:dynstocks/redux/middlewares/ticker_data.middlewares.dart';
import 'package:dynstocks/redux/middlewares/transactions.middlewares.dart';
import 'package:dynstocks/redux/middlewares/user_info.middlewares.dart';
import 'package:dynstocks/views/screens/enter_local_user_creds_screen.dart';
import 'package:dynstocks/views/screens/events_today_screen.dart';
import 'package:dynstocks/views/screens/view_dynstocks_list_screen.dart';
import 'package:dynstocks/views/screens/view_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yahoofin/yahoofin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final Store<AppState> appStore = Store<AppState>(
  appReducer,
  initialState: AppState.initialState(),
  middleware: [
    transactionsMiddleWare,
    dynStocksMiddleWare,
    tickerDataMiddleWare,
    kotakStockAPIMiddleWare,
    userInfoMiddleWare,
    authMiddleWare,
  ],
);

final yFin = YahooFin();
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  DateTime now = DateTime.now();
  final String? userId = prefs.getString('userId');
  final String? accessCode =
      prefs.getString('accessCode ${now.day}/${now.month}/${now.year}');

  if (userId == null) {
    runApp(StoreProvider(
        store: appStore,
        child: MaterialApp(
          home:
              EnterLocalUserCredsScreen(shouldAskForUsernameAndPassword: true),
          navigatorObservers: [routeObserver],
        )));
  } else if (accessCode == null) {
    runApp(StoreProvider(
        store: appStore,
        child: MaterialApp(
          home:
              EnterLocalUserCredsScreen(shouldAskForUsernameAndPassword: false),
          navigatorObservers: [routeObserver],
        )));
  } else {
    // Directly go to events_today_screen
    runApp(StoreProvider(
        store: appStore,
        child: MaterialApp(
          home: EventsTodayScreen(),
          navigatorObservers: [routeObserver],
        )));
  }
}
