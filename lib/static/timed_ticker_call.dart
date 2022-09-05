import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:dynstocks/main.dart';
import 'package:dynstocks/redux/actions/local_user_creds.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimedTickerCall {
  static List<Timer> timerQueueForDynStocks = List.empty(growable: true);
  static bool startTimedTickerCallForDynStocks(BuildContext context) {
    if (timerQueueForDynStocks.length == 1) {
      return true;
    }
    if (appStore.state.timedTickerPeriod == -1) {
      SharedPreferences.getInstance().then((prefs) {
        int? timedTickerPeriod = prefs.getInt('timedTickerPeriod');
        StoreProvider.of<AppState>(context).dispatch(SetTimedTickerPeriodAction(
            timedTickerPeriod: timedTickerPeriod as int));
      });
    }
    if (appStore.state.allDynStocks.loaded &&
        !appStore.state.allDynStocks.loading &&
        appStore.state.allDynStocks.data.isNotEmpty &&
        appStore.state.timedTickerPeriod != -1) {
      DateTime now = DateTime.now();
      bool sellCondition = (now.hour < 9) ||
          now.hour >= 16 ||
          (now.hour == 9 && now.minute < 15) ||
          (now.hour == 15 && now.minute > 30) ||
          (now.weekday > 5);
      if (!sellCondition) {
        Timer timer = Timer.periodic(
            Duration(seconds: appStore.state.timedTickerPeriod), (timer) {
          print('Here');
          if (!appStore.state.allTransactions.loading &&
              !appStore.state.allDynStocks.loading &&
              !appStore.state.allDynStocks.creating &&
              !appStore.state.allDynStocks.updating &&
              !appStore.state.allDynStocks.deleting &&
              !appStore.state.allTickerData.loading) {
            print('Tick : ' + timer.tick.toString());
            StoreProvider.of<AppState>(context)
                .dispatch(GetAllTickerDataAction());
            DateTime now = DateTime.now();
            bool stockMarketClosed = (now.hour < 9) ||
                now.hour >= 16 ||
                (now.hour == 9 && now.minute < 15) ||
                (now.hour == 15 && now.minute > 30) ||
                (now.weekday > 5);
            if (stockMarketClosed) {
              stopTimedTickerCallForDynStocks();
            }
          }
        });
        timerQueueForDynStocks.insert(0, timer);
        print("Timer Created");
      } else {
        StoreProvider.of<AppState>(context).dispatch(GetAllTickerDataAction());
      }

      return true;
    }
    return false;
  }

  static void stopTimedTickerCallForDynStocks() {
    if (timerQueueForDynStocks.length == 1) {
      timerQueueForDynStocks
          .elementAt(max(timerQueueForDynStocks.length - 1, 0))
          .cancel();
      timerQueueForDynStocks.removeLast();
      print("Timer Stopped");
    }
  }

  static Timer? timerForCustomStock;
}
