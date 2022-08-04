import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/user_info.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/user_info.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:dynstocks/services/user_info.service.dart';
import 'package:redux/redux.dart';

void userInfoMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetUserInfoAction) {
    UserInfoService().getUserInfo(action.userId).then((response) {
      store.dispatch(GetUserInfoSuccessAction(userInfo: response));
    }).catchError((error) {
      store.dispatch(GetUserInfoFailAction(error: error));
    });
  }
  next(action);
}
