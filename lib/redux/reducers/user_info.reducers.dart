import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/user_info.actions.dart';
import 'package:dynstocks/redux/state/dyn_stocks.state.dart';
import 'package:dynstocks/redux/state/user_info.state.dart';

UserInfoState userInfoReducer(UserInfoState state, dynamic action) {
  if (action is GetUserInfoAction) {
    return UserInfoState.updatedState(
      loading: true,
      loaded: false,
      loadFailed: false,
      deleting: state.deleting,
      deleted: state.deleted,
      deleteFailed: state.deleteFailed,
      data: state.data,
    );
  }
  if (action is GetUserInfoSuccessAction) {
    return UserInfoState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: false,
        deleting: state.deleting,
        deleted: state.deleted,
        deleteFailed: state.deleteFailed,
        data: action.userInfo,
        error: null);
  }
  if (action is GetUserInfoFailAction) {
    return UserInfoState.updatedState(
        loading: false,
        loaded: false,
        loadFailed: true,
        data: null,
        deleting: state.deleting,
        deleted: state.deleted,
        deleteFailed: state.deleteFailed,
        error: action.error);
  }

  if (action is DeleteUserAction) {
    return UserInfoState.updatedState(
      loading: state.loading,
      loaded: state.loaded,
      loadFailed: state.loadFailed,
      deleting: true,
      deleted: false,
      deleteFailed: false,
      data: state.data,
    );
  }
  if (action is DeleteUserSuccessAction) {
    return UserInfoState.updatedState(
      loading: state.loading,
      loaded: state.loaded,
      loadFailed: state.loadFailed,
      deleting: false,
      deleted: true,
      deleteFailed: false,
      data: state.data,
    );
  }
  if (action is DeleteUserFailAction) {
    return UserInfoState.updatedState(
      loading: state.loading,
      loaded: state.loaded,
      loadFailed: state.loadFailed,
      deleting: false,
      deleted: false,
      deleteFailed: true,
      data: state.data,
    );
  }
  return state;
}
