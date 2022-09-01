// To parse this JSON data, do
//
//     final transactions = transactionsFromJson(jsonString);

import 'dart:convert';

import 'dart:convert';

TransactionsResponse transactionsResponseFromJson(String str) =>
    TransactionsResponse.fromJson(json.decode(str));

String transactionsResponseToJson(TransactionsResponse data) =>
    json.encode(data.toJson());

class TransactionsResponse {
  TransactionsResponse({
    required this.hasMore,
    required this.items,
  });

  bool hasMore;
  List<Transaction> items;

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) =>
      TransactionsResponse(
        hasMore: json["hasMore"],
        items: List<Transaction>.from(
            json["items"].map((x) => Transaction.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "hasMore": hasMore,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

List<Transaction> transactionsFromJson(String str) => List<Transaction>.from(
    json.decode(str).map((x) => Transaction.fromJson(x)));

String transactionsToJson(List<Transaction> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Transaction {
  Transaction({
    required this.userId,
    required this.dynStockId,
    required this.transactionId,
    required this.transactionTime,
    required this.type,
    required this.noOfStocks,
    required this.stockCode,
    required this.stockPrice,
    required this.amount,
  });

  Id userId;
  Id dynStockId;
  Id transactionId;
  TransactionTime transactionTime;
  String type;
  int noOfStocks;
  String stockCode;
  double stockPrice;
  double amount;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        userId: Id.fromJson(json["userId"]),
        dynStockId: Id.fromJson(json["dynStockId"]),
        transactionId: Id.fromJson(json["transactionId"]),
        transactionTime: TransactionTime.fromJson(json["transactionTime"]),
        type: json["type"],
        noOfStocks: json["noOfStocks"],
        stockCode: json["stockCode"],
        stockPrice: json["stockPrice"],
        amount: json["amount"],
      );

  Map<String, dynamic> toJson() => {
        "userId": userId.toJson(),
        "dynStockId": dynStockId.toJson(),
        "transactionId": transactionId.toJson(),
        "transactionTime": transactionTime.toJson(),
        "type": type,
        "noOfStocks": noOfStocks,
        "stockCode": stockCode,
        "stockPrice": stockPrice,
        "amount": amount,
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

class TransactionTime {
  TransactionTime({
    required this.date,
  });

  int date;

  factory TransactionTime.fromJson(Map<String, dynamic> json) =>
      TransactionTime(
        date: json["\u0024date"],
      );

  Map<String, dynamic> toJson() => {
        "\u0024date": date,
      };
}

class TransactionBody {
  String transactionId;
  String type;
  int noOfStocks;
  String stockCode;
  double stockPrice;
  int? stocksAvailableForTrade;
  TransactionBody(
      {required this.transactionId,
      required this.type,
      required this.noOfStocks,
      required this.stockCode,
      required this.stockPrice,
      this.stocksAvailableForTrade});

  factory TransactionBody.fromJson(Map<String, dynamic> json) {
    if (json['stocksAvailableForTrade'] != null) {
      return TransactionBody(
          transactionId: json['transactionId'],
          type: json['type'],
          noOfStocks: json['noOfStocks'],
          stockCode: json['stockCode'],
          stockPrice: json['stockPrice'],
          stocksAvailableForTrade: json['stocksAvailableForTrade']);
    } else {
      return TransactionBody(
        transactionId: json['transactionId'],
        type: json['type'],
        noOfStocks: json['noOfStocks'],
        stockCode: json['stockCode'],
        stockPrice: json['stockPrice'],
      );
    }
  }
  Map<String, dynamic> toJson() {
    if (stocksAvailableForTrade != null) {
      return {
        "transactionId": transactionId,
        "type": type,
        "noOfStocks": noOfStocks,
        "stockCode": stockCode,
        "stockPrice": stockPrice,
        "stocksAvailableForTrade": stocksAvailableForTrade,
      };
    } else {
      return {
        "transactionId": transactionId,
        "type": type,
        "noOfStocks": noOfStocks,
        "stockCode": stockCode,
        "stockPrice": stockPrice,
      };
    }
  }
}

TransactionsCreate transactionsCreateFromJson(String str) =>
    TransactionsCreate.fromJson(json.decode(str));

String transactionsCreateToJson(TransactionsCreate data) =>
    json.encode(data.toJson());

class TransactionsCreate {
  TransactionsCreate({
    required this.creating,
    required this.created,
    required this.createFailed,
    this.error,
  });

  bool creating;
  bool created;
  bool createFailed;
  dynamic error;

  factory TransactionsCreate.fromJson(Map<String, dynamic> json) =>
      TransactionsCreate(
        creating: json["creating"],
        created: json["created"],
        createFailed: json["createFailed"],
      );

  Map<String, dynamic> toJson() => {
        "creating": creating,
        "created": created,
        "createFailed": createFailed,
      };
}
