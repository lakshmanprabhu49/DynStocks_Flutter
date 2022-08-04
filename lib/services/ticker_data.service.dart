import 'dart:collection';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/models/yahoo_finance_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:yahoofin/yahoofin.dart';

class TickerDataService {
  Future<TickerData> getTickerData(String ticker) async {
    StockInfo info = yFin.getStockInfo(ticker: ticker);
    StockQuote price = await yFin.getPrice(stockInfo: info);
    StockQuote priceChange = await yFin.getPriceChange(stockInfo: info);
    return TickerData(
      stockInfo: info,
      price: price,
      priceChange: priceChange,
    );
  }
}
