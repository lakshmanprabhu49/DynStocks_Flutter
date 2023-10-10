// To parse this JSON data, do
//
//     final dynStocksRealTimePrice = dynStocksRealTimePriceFromJson(jsonString);

import 'dart:convert';

DynStocksRealTimePrice dynStocksRealTimePriceFromJson(String str) =>
    DynStocksRealTimePrice.fromJson(json.decode(str));

String dynStocksRealTimePriceToJson(DynStocksRealTimePrice data) =>
    json.encode(data.toJson());

class DynStocksRealTimePrice {
  String userId;
  List<StockDetail> stockDetails;

  DynStocksRealTimePrice({
    required this.userId,
    required this.stockDetails,
  });

  factory DynStocksRealTimePrice.fromJson(Map<String, dynamic> json) =>
      DynStocksRealTimePrice(
        userId: json["userId"],
        stockDetails: List<StockDetail>.from(
            json["stockDetails"].map((x) => StockDetail.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "stockDetails": List<dynamic>.from(stockDetails.map((x) => x.toJson())),
      };
}

class StockDetail {
  String stockCode;
  double currentLocalMaximumPrice;
  double currentLocalMinimumPrice;

  StockDetail({
    required this.stockCode,
    required this.currentLocalMaximumPrice,
    required this.currentLocalMinimumPrice,
  });

  factory StockDetail.fromJson(Map<String, dynamic> json) => StockDetail(
        stockCode: json["stockCode"],
        currentLocalMaximumPrice: json["currentLocalMaximumPrice"],
        currentLocalMinimumPrice: json["currentLocalMinimumPrice"],
      );

  Map<String, dynamic> toJson() => {
        "stockCode": stockCode,
        "currentLocalMaximumPrice": currentLocalMaximumPrice,
        "currentLocalMinimumPrice": currentLocalMinimumPrice,
      };
}
