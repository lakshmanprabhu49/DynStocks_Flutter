import 'package:dynstocks/models/user_info.dart';

class GetUserInfoAction {
  String userId;
  GetUserInfoAction({required this.userId});
}

class GetUserInfoSuccessAction {
  final UserInfo userInfo;
  GetUserInfoSuccessAction({required this.userInfo});
}

class GetUserInfoFailAction {
  final dynamic error;
  GetUserInfoFailAction({required this.error});
}

// class CreateUserInfoAction {
//   String userId;
//   String dynStockId;
//   String instrumentToken;
//   UserInfoBody body;
//   CreateUserInfoAction(
//       {required this.userId,
//       required this.instrumentToken,
//       required this.dynStockId,
//       required this.body});
// }

// class CreateUserInfoSuccessAction {
//   final UserInfo transaction;
//   CreateUserInfoSuccessAction({required this.transaction});
// }

// class CreateUserInfoFailAction {
//   final dynamic error;
//   CreateUserInfoFailAction({required this.error});
// }
