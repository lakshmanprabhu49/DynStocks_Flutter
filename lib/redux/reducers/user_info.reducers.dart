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
      data: state.data,
    );
  }
  if (action is GetUserInfoSuccessAction) {
    return UserInfoState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: false,
        data: action.userInfo,
        error: null);
  }
  if (action is GetUserInfoFailAction) {
    return UserInfoState.updatedState(
        loading: false,
        loaded: false,
        loadFailed: true,
        data: null,
        error: action.error);
  }
  return state;
}
