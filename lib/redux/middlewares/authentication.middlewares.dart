import 'package:dynstocks/models/email.dart';
import 'package:dynstocks/redux/actions/authentication.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/authentication.service.dart';
import 'package:dynstocks/services/emailjs.service.dart';
import 'package:redux/redux.dart';

void authMiddleWare(
    Store<AppState> store, dynamic action, NextDispatcher next) async {
  if (action is LoginAction) {
    AuthService()
        .login(action.authBody.username, action.authBody.password)
        .then((response) {
      store.dispatch(LoginSuccessAction(authResponse: response));
    }).catchError((error) {
      String emailBodyLine1 = '$error';
      EmailJSService()
          .sendEmail(Email(
              username: 'Myself',
              subject: 'Error while Logging in',
              title: 'Error while Logging in for ${action.authBody.username}',
              subtitle:
                  'The following error resulted while logging in for ${action.authBody.username}',
              body: emailBodyLine1))
          .then((value) {})
          .catchError((error) {});
      store.dispatch(LoginFailAction(error: error));
    });
  }
  if (action is LogoutAction) {
    AuthService().logout(action.userId).then((response) {
      store.dispatch(LogoutSuccessAction(authResponse: response));
    }).catchError((error) {
      String emailBodyLine1 = '$error';
      EmailJSService()
          .sendEmail(Email(
              username: 'Myself',
              subject: 'Error while Logging out',
              title: 'Error while Logging out',
              subtitle: 'The following error resulted while logging out',
              body: emailBodyLine1))
          .then((value) {})
          .catchError((error) {});
      store.dispatch(LogoutFailAction(error: error));
    });
  }
  next(action);
}
