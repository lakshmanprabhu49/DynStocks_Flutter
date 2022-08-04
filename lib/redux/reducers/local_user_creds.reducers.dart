import 'package:dynstocks/redux/actions/local_user_creds.actions.dart';

String userIdReducer(String state, dynamic action) {
  if (action is SetUserIdAction) {
    return action.userId;
  }
  return state;
}

String accessCodeReducer(String state, dynamic action) {
  if (action is SetAccessCodeAction) {
    return action.accessCode;
  }
  return state;
}
