import 'dart:convert';
import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/authentication.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class AuthService {
  Future<AuthResponse> login(String username, String password) async {
    Uri url =
        Uri.parse('${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/auth/login');
    var client = http.Client();
    var response = await client.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
        },
        body: jsonEncode(AuthBody(username: username, password: password)));
    String res = response.body;
    return authResponseFromJson(res);
  }

  Future<AuthResponse> logout(String userId) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/auth/logout/$userId');
    var client = http.Client();
    var response = await client.post(url,
        headers: {'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID});
    String res = response.body;
    return authResponseFromJson(res);
  }
}
