import 'dart:collection';
import 'dart:io';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TransactionsService {
  Future<List<Transaction>> getTransactionsForDate(String userId,
      {String date = ''}) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/transactions?accessCode=${appStore.state.accessCode}');
    if (date.isNotEmpty) {
      url = Uri.parse(
          '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/transactions?accessCode=${appStore.state.accessCode}&&date=$date');
    }
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });

    String res = response.body;

    return transactionsFromJson(res);
  }

  Future<Transaction> createTransaction(
      String userId, String dynStockId, TransactionBody body) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_PROD"]}/$userId/dynStocks/$dynStockId/transactions?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.post(url, body: jsonEncode(body), headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });

    String res = response.body;
    return Transaction.fromJson(jsonDecode(res));
  }
}
