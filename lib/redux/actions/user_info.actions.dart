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
