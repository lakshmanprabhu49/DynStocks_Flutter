import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:dynstocks/models/user_info.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/user_info.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:dynstocks/services/gmail_error_message.service.dart';
import 'package:dynstocks/services/kotak_stock_api.service.dart';
import 'package:dynstocks/services/user_info.service.dart';
import 'package:redux/redux.dart';

void userInfoMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is GetUserInfoAction) {
    UserInfoService().getUserInfo(action.userId).then((response) {
      store.dispatch(GetUserInfoSuccessAction(userInfo: response));
    }).catchError((error) {
      print(error);
      String emailBodyLine1 = '$error';
      EmailJSService()
          .sendEmail(Email(
              username: 'Myself',
              subject: 'Error while getting user info for ${action.userId}',
              title: 'Error while getting user info for ${action.userId}',
              subtitle: 'Error while getting user info for ${action.userId}',
              body: emailBodyLine1))
          .then((value) {})
          .catchError((error) {
        print(error);
      });
      store.dispatch(GetUserInfoFailAction(error: error));
    });
  }
  if (action is DeleteUserAction) {
    UserInfoService().deleteUser(action.userId).then((response) {
      store.dispatch(DeleteUserSuccessAction(userId: action.userId));
    }).catchError((error) {
      print(error);
      String emailBodyLine1 = '$error';
      EmailJSService()
          .sendEmail(Email(
              username: 'Myself',
              subject: 'Error while getting user info for ${action.userId}',
              title: 'Error while getting user info for ${action.userId}',
              subtitle: 'Error while getting user info for ${action.userId}',
              body: emailBodyLine1))
          .then((value) {})
          .catchError((error) {
        print(error);
      });
      store.dispatch(DeleteUserFailAction(error: error));
    });
  }
  next(action);
}
