import 'dart:convert';

import 'package:dynstocks/models/transactions.dart';

List<DynStock> dynStockFromJson(String str) =>
    List<DynStock>.from(json.decode(str).map((x) => DynStock.fromJson(x)));

String dynStockToJson(List<DynStock> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DynStock {
  DynStock({
    required this.userId,
    required this.dynStockId,
    required this.stockCode,
    required this.yFinStockCode,
    required this.stockName,
    required this.exchange,
    required this.stockType,
    required this.instrumentToken,
    required this.DSTPUnit,
    required this.noOfStocks,
    required this.HETolerance,
    required this.LETolerance,
    this.lastTradedPrice = 0.0,
    this.lastTransactionType = 'BUY',
    this.lastTransactionTime = null,
    this.stocksAvailableForTrade = 0,
    this.BTPr = 0.0,
    this.STPr = 0.0,
    this.BTPe = 0.0,
    this.STPe = 0.0,
    this.stallTransactions = false,
    this.transactions = const [],
  });

  Id userId;
  Id dynStockId;
  String stockCode;
  String instrumentToken;
  String yFinStockCode;
  String stockName;
  String exchange;
  String stockType;
  String DSTPUnit;
  int noOfStocks;
  double lastTradedPrice;
  String lastTransactionType;
  TransactionTime? lastTransactionTime;
  int stocksAvailableForTrade;
  bool stallTransactions;
  double HETolerance;
  double LETolerance;
  double BTPr;
  double STPr;
  double BTPe;
  double STPe;
  List<Transaction> transactions;

  factory DynStock.fromJson(Map<String, dynamic> json) => DynStock(
        userId: Id.fromJson(json["userId"]),
        dynStockId: Id.fromJson(json["dynStockId"]),
        stockCode: json["stockCode"],
        instrumentToken: json["instrumentToken"],
        yFinStockCode: json["yFinStockCode"],
        stockName: json["stockName"],
        exchange: json["exchange"],
        stockType: json["stockType"],
        DSTPUnit: json["DSTPUnit"],
        lastTradedPrice: json["lastTradedPrice"],
        lastTransactionType: json["lastTransactionType"],
        lastTransactionTime:
            TransactionTime.fromJson(json["lastTransactionTime"]),
        stocksAvailableForTrade: json["stocksAvailableForTrade"],
        BTPr: json["BTPr"],
        BTPe: json["BTPe"],
        STPr: json["STPr"],
        STPe: json["STPe"],
        noOfStocks: json["noOfStocks"],
        stallTransactions: json["stallTransactions"],
        HETolerance: json["HETolerance"],
        LETolerance: json["LETolerance"],
        transactions: List<Transaction>.from(
            json["transactions"].map((x) => Transaction.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "userId": userId.toJson(),
        "dynStockId": dynStockId.toJson(),
        "stockCode": stockCode,
        "instrumentToken": instrumentToken,
        "yFinStockCode": yFinStockCode,
        "stockName": stockName,
        "exchange": exchange,
        "stockType": stockType,
        "DSTPUnit": DSTPUnit,
        "lastTradedPrice": lastTradedPrice,
        "lastTransactionType": lastTransactionType,
        "lastTransactionTime": lastTransactionTime?.toJson(),
        "stocksAvailableForTrade": stocksAvailableForTrade,
        "BTPr": BTPr,
        "BTPe": BTPe,
        "STPr": STPr,
        "STPe": STPe,
        "noOfStocks": noOfStocks,
        "stallTransactions": stallTransactions,
        'HETolerance': HETolerance,
        'LETolerance': LETolerance,
        "transactions": List<dynamic>.from(transactions.map((x) => x.toJson())),
      };
}

class Id {
  Id({
    required this.uuid,
  });

  String uuid;

  factory Id.fromJson(Map<String, dynamic> json) => Id(
        uuid: json["\u0024uuid"],
      );

  Map<String, dynamic> toJson() => {
        "\u0024uuid": uuid,
      };
}

class DynStockBody {
  DynStockBody({
    required this.stockCode,
    required this.instrumentToken,
    required this.yFinStockCode,
    required this.stockName,
    required this.exchange,
    required this.stockType,
    required this.DSTPUnit,
    required this.noOfStocks,
    required this.HETolerance,
    required this.LETolerance,
    this.BTPr = 0.0,
    this.STPr = 0.0,
    this.BTPe = 0.0,
    this.STPe = 0.0,
    this.stallTransactions = false,
    this.transactionForCreateDynStock = null,
  });

  String stockCode;
  String instrumentToken;
  String yFinStockCode;
  String stockName;
  String exchange;
  String stockType;
  String DSTPUnit;
  int noOfStocks;
  double BTPr;
  double STPr;
  double BTPe;
  double STPe;
  bool stallTransactions;
  double HETolerance;
  double LETolerance;
  TransactionBody? transactionForCreateDynStock;

  factory DynStockBody.fromJson(Map<String, dynamic> json) => DynStockBody(
        stockCode: json["stockCode"],
        instrumentToken: json["instrumentToken"],
        yFinStockCode: json["yFinStockCode"],
        stockName: json["stockName"],
        exchange: json["exchange"],
        stockType: json["stockType"],
        DSTPUnit: json["DSTPUnit"],
        BTPr: json["BTPr"],
        BTPe: json["BTPe"],
        STPr: json["STPr"],
        STPe: json["STPe"],
        noOfStocks: json["noOfStocks"],
        stallTransactions: json["stallTransactions"],
        HETolerance: json["HETolerance"],
        LETolerance: json["LETolerance"],
        transactionForCreateDynStock:
            TransactionBody.fromJson(json["transactionForCreateDynStock"]),
      );

  Map<String, dynamic> toJson() => {
        "stockCode": stockCode,
        "instrumentToken": instrumentToken,
        "yFinStockCode": yFinStockCode,
        "stockName": stockName,
        "exchange": exchange,
        "stockType": stockType,
        "DSTPUnit": DSTPUnit,
        "BTPr": BTPr,
        "BTPe": BTPe,
        "STPr": STPr,
        "STPe": STPe,
        "noOfStocks": noOfStocks,
        "stallTransactions": stallTransactions,
        'HETolerance': HETolerance,
        'LETolerance': LETolerance,
        "transactionForCreateDynStock": transactionForCreateDynStock?.toJson(),
      };
}
