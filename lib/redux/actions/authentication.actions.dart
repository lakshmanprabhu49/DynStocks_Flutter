import 'package:dynstocks/models/authentication.dart';

class LoginAction {
  AuthBody authBody;
  LoginAction({required this.authBody});
}

class LoginSuccessAction {
  final AuthResponse authResponse;
  LoginSuccessAction({required this.authResponse});
}

class LoginFailAction {
  final dynamic error;
  LoginFailAction({required this.error});
}

class LogoutAction {
  String userId;
  LogoutAction({required this.userId});
}

class LogoutSuccessAction {
  final AuthResponse authResponse;
  LogoutSuccessAction({required this.authResponse});
}

class LogoutFailAction {
  final dynamic error;
  LogoutFailAction({required this.error});
}
