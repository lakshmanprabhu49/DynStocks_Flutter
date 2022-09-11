import 'dart:collection';
import 'dart:io';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/error_class.dart';
import 'package:dynstocks/models/user_info.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserInfoService {
  Future<UserInfo> getUserInfo(String userId) async {
    Uri url =
        Uri.parse('${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/users/$userId');
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return UserInfo.fromJson(jsonDecode(res));
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<String> deleteUser(String userId) async {
    Uri url =
        Uri.parse('${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/users/$userId');
    var client = http.Client();
    var response = await client.delete(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return userId;
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }
}
