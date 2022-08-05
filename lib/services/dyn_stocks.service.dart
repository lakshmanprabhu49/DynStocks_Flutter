import 'dart:collection';
import 'dart:io';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DynStocksService {
  Future<List<DynStock>> getDynStocks(String userId) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_LOCAL"]}/$userId/dynStocks?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    return dynStockFromJson(res);
  }

  Future<DynStock> createDynStock(String userId, DynStockBody body) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_LOCAL"]}/$userId/dynStocks?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.post(url, body: jsonEncode(body), headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    return DynStock.fromJson(jsonDecode(res));
  }

  Future<DynStock> updateDynStock(
      String userId, String dynStockId, DynStockBody body) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_LOCAL"]}/$userId/dynStocks/$dynStockId?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.put(url, body: jsonEncode(body), headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    return DynStock.fromJson(jsonDecode(res));
  }

  Future<String> deleteDynStock(String userId, String dynStockId) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_LOCAL"]}/$userId/dynStocks/$dynStockId?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.delete(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode == 204) {
      return dynStockId;
    }
    return '';
  }
}
