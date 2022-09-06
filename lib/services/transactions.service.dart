import 'dart:collection';
import 'dart:io';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/error_class.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TransactionsService {
  Future<TransactionsResponse> getTransactionsForDate(String userId,
      {String date = '',
      int limit = 0,
      int offset = 0,
      String sortCriterion = 'TransactionTime',
      sortDirection = 'DESC',
      String dynStockId = '',
      String filterCriterionStocks = '',
      String filterCriterionDay = ''}) async {
    String urlEndPoint =
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_LOCAL"]}/$userId/transactions?accessCode=${appStore.state.accessCode}';
    if (dynStockId.isNotEmpty) {
      urlEndPoint =
          '${dotenv.env["DYNSTOCKS_API_ENDPOINT_LOCAL"]}/$userId/dynStocks/$dynStockId/transactions?accessCode=${appStore.state.accessCode}';
    }
    String urlParams =
        '&limit=$limit&offset=$offset&sortCriterion=$sortCriterion&sortDirection=$sortDirection';
    if (filterCriterionStocks.isNotEmpty) {
      urlParams = '$urlParams&filterCriterionStocks=$filterCriterionStocks';
    }
    if (filterCriterionDay.isNotEmpty) {
      urlParams = '$urlParams&filterCriterionDay=$filterCriterionDay';
    }
    if (date.isNotEmpty) {
      urlParams = '$urlParams&date=$date';
    }
    String urlString = '$urlEndPoint$urlParams';
    Uri url = Uri.parse(urlString);
    var client = http.Client();
    var response = await client.get(url, headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });

    String res = response.body;
    if (response.statusCode < 400) {
      return transactionsResponseFromJson(res);
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }

  Future<Transaction> createTransaction(
      String userId, String dynStockId, TransactionBody body) async {
    Uri url = Uri.parse(
        '${dotenv.env["DYNSTOCKS_API_ENDPOINT_LOCAL"]}/$userId/dynStocks/$dynStockId/transactions?accessCode=${appStore.state.accessCode}');
    var client = http.Client();
    var response = await client.post(url, body: jsonEncode(body), headers: {
      HttpHeaders.authorizationHeader:
          'Bearer ${appStore.state.kotakStockAPI.jwtToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
      'x-request-id': appStore.state.DYNSTOCKS_X_REQUEST_ID
    });

    String res = response.body;
    if (response.statusCode < 400) {
      return Transaction.fromJson(jsonDecode(res));
    } else {
      throw Exception(ErrorClass.fromJson(jsonDecode(res)).message);
    }
  }
}
