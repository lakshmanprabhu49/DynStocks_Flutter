// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:io';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/error_class.dart';
import 'package:dynstocks/models/kotak_stock_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KotakStockAPIService {
  Future<KotakStockApiPlaceOrderResponse?> placeOrder(
    String userId,
    String accessCode,
    KotakStockAPIPlaceOrderBody body,
  ) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/kotakStock/placeOrder?accessCode=$accessCode');
    var client = http.Client();
    var response = await client.post(url, body: jsonEncode(body), headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return kotakStockApiPlaceOrderResponseFromJson(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<KotakStockApiPositionsResponse?> getPositions(String userId,
      String accessCode, EPositions position, String instrumentToken) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/kotakStock/positions/${position.name}?accessCode=$accessCode');
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return kotakStockApiPositionsResponseFromJson(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<KotakStockApiOrderReportsResponse?> getOrderReport(String userId,
      String accessCode, int orderId, String instrumentToken) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/kotakStock/orderReport/$orderId?accessCode=$accessCode');
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return kotakStockApiOrderReportsResponseFromJson(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<KotakStockApiLoginResponse?> login(
      String userId, String accessCode) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/kotakStock/login?accessCode=$accessCode');
    var client = http.Client();
    var response = await client.post(url,
        headers: {'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID});
    String res = response.body;
    if (response.statusCode < 400) {
      return kotakStockApiLoginResponseFromJson(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }
}
