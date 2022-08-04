import 'package:dynstocks/models/authentication.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/transactions.dart';

class AuthState {
  bool loggingIn = false;
  bool loggedIn = false;
  bool loginFailed = false;
  bool loggingOut = false;
  bool loggedOut = false;
  bool logoutFailed = false;
  AuthResponse? data;
  dynamic error;

  AuthState.initialState() {
    loggingIn = false;
    loggedIn = false;
    loginFailed = false;
    loggingOut = false;
    loggedOut = false;
    logoutFailed = false;
    data = null;
    error = null;
  }

  AuthState.updatedState(
      {required this.loggingIn,
      required this.loggedIn,
      required this.loginFailed,
      required this.loggingOut,
      required this.loggedOut,
      required this.logoutFailed,
      required this.data,
      this.error});
}
