import 'package:dynstocks/models/user_info.dart';

class UserInfoState {
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  bool deleting = false;
  bool deleted = false;
  bool deleteFailed = false;
  UserInfo? data;
  dynamic error;

  UserInfoState.initialState() {
    loading = false;
    loaded = false;
    loadFailed = false;
    deleting = false;
    deleted = false;
    deleteFailed = false;
    data = null;
    error = null;
  }

  UserInfoState.updatedState(
      {required this.loading,
      required this.loaded,
      required this.loadFailed,
      required this.deleting,
      required this.deleted,
      required this.deleteFailed,
      required this.data,
      this.error});
}
