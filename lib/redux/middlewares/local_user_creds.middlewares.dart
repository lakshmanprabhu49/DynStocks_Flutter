import 'package:dynstocks/redux/actions/local_user_creds.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

void localUserCredsMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is SetTimedTickerPeriodAction) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('timedTickerPeriod', action.timedTickerPeriod);
    });
  }
  next(action);
}
