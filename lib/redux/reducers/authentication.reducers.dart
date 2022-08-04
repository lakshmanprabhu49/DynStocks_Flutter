import 'package:dynstocks/main.dart';
import 'package:dynstocks/redux/actions/authentication.actions.dart';
import 'package:dynstocks/redux/state/authentication.state.dart';
import 'package:dynstocks/redux/state/dyn_stocks.state.dart';

AuthState authReducer(AuthState state, dynamic action) {
  if (action is LoginAction) {
    return AuthState.updatedState(
      loggingIn: true,
      loggedIn: false,
      loginFailed: false,
      loggingOut: state.loggingOut,
      loggedOut: state.loggedOut,
      logoutFailed: state.logoutFailed,
      data: null,
    );
  }
  if (action is LoginSuccessAction) {
    appStore.state.userId = action.authResponse.userId;
    return AuthState.updatedState(
      loggingIn: false,
      loggedIn: true,
      loginFailed: false,
      loggingOut: state.loggingOut,
      loggedOut: state.loggedOut,
      logoutFailed: state.logoutFailed,
      data: action.authResponse,
    );
  }
  if (action is LoginFailAction) {
    return AuthState.updatedState(
        loggingIn: false,
        loggedIn: false,
        loginFailed: true,
        loggingOut: state.loggingOut,
        loggedOut: state.loggedOut,
        logoutFailed: state.logoutFailed,
        data: null,
        error: action.error);
  }
  if (action is LogoutAction) {
    return AuthState.updatedState(
      loggingIn: state.loggingIn,
      loggedIn: state.loggedIn,
      loginFailed: state.loginFailed,
      loggingOut: true,
      loggedOut: false,
      logoutFailed: false,
      data: null,
    );
  }
  if (action is LogoutSuccessAction) {
    return AuthState.updatedState(
      loggingIn: false,
      loggedIn: false,
      loginFailed: false,
      loggingOut: false,
      loggedOut: true,
      logoutFailed: false,
      data: action.authResponse,
    );
  }
  if (action is LogoutFailAction) {
    return AuthState.updatedState(
        loggingIn: state.loggingIn,
        loggedIn: state.loggedIn,
        loginFailed: state.loginFailed,
        loggingOut: false,
        loggedOut: false,
        logoutFailed: true,
        data: null,
        error: action.error);
  }
  return state;
}
