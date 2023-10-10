import 'dart:convert';
import 'dart:io';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/dyn_stocks_real_time_price.dart';
import 'package:dynstocks/models/error_class.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DynStocksRealTimePriceService {
  Future<DynStocksRealTimePrice> getRealTimePrice(
    String userId,
  ) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/realTimePrice/$userId?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID,
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return dynStocksRealTimePriceFromJson(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<DynStocksRealTimePrice> putRealTimePrice(
    String userId,
    List<StockDetail> stockDetails,
  ) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/realTimePrice/$userId?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client
        .put(url, body: jsonEncode({'stockDetails': stockDetails}), headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID,
      HttpHeaders.contentTypeHeader: 'application/json',
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return dynStocksRealTimePriceFromJson(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }
}
