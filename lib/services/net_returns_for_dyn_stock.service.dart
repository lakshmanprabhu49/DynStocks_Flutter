import 'dart:collection';
import 'dart:io';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/error_class.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NetReturnsForDynStockService {
  Future<double> getNetReturnsForDynStock(
      String userId, String dynStockId, String period) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/dynStocks/$dynStockId/netReturns?accessCode=${appStore.state.accessCode}&period=$period');
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });
    String res = response.body;
    if (response.statusCode < 400) {
      return double.parse(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }
}
