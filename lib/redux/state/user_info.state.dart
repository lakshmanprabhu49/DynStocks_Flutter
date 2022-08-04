import 'package:dynstocks/models/user_info.dart';

class UserInfoState {
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  UserInfo? data;
  dynamic error;

  UserInfoState.initialState() {
    loading = false;
    loaded = false;
    loadFailed = false;
    data = null;
    error = null;
  }

  UserInfoState.updatedState(
      {required this.loading,
      required this.loaded,
      required this.loadFailed,
      required this.data,
      this.error});
}
