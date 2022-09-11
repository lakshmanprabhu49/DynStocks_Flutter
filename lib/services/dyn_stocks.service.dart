import 'dart:collection';
import 'dart:io';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/error_class.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DynStocksService {
  Future<List<DynStock>> getDynStocks(String userId) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/dynStocks?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      if (res.substring(0, 2) == '[]') {
        return [];
      }
      return dynStockFromJson(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<DynStock> createDynStock(String userId, DynStockBody body) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/dynStocks?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.post(url, body: jsonEncode(body), headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return DynStock.fromJson(jsonDecode(res));
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<DynStock> updateDynStock(
      String userId, String dynStockId, DynStockBody body) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/dynStocks/$dynStockId?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.put(url, body: jsonEncode(body), headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return DynStock.fromJson(jsonDecode(res));
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<String> deleteDynStock(String userId, String dynStockId) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/dynStocks/$dynStockId?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.delete(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return dynStockId;
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }
}
