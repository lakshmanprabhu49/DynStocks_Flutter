// To parse this JSON data, do
//
//     final userInfo = userInfoFromJson(jsonString);

import 'dart:convert';

import 'package:dynstocks/models/dyn_stocks.dart';

List<UserInfo> userInfoFromJson(String str) =>
    List<UserInfo>.from(json.decode(str).map((x) => UserInfo.fromJson(x)));

String userInfoToJson(List<UserInfo> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class UserInfo {
  UserInfo({
    required this.id,
    required this.userId,
    required this.username,
    required this.noOfDynStocksOwned,
    required this.noOfTransactionsMade,
    required this.netReturns,
    this.dynStocks,
  });

  Id id;
  String userId;
  String username;
  int noOfDynStocksOwned;
  int noOfTransactionsMade;
  double netReturns;
  List<DynStock>? dynStocks;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    if (json["dynStocks"] == null) {
      return UserInfo(
        id: Id.fromJson(json["_id"]),
        userId: json["userId"],
        username: json["username"],
        noOfDynStocksOwned: json["noOfDynStocksOwned"],
        noOfTransactionsMade: json["noOfTransactionsMade"],
        netReturns: json["netReturns"],
      );
    } else {
      return UserInfo(
        id: Id.fromJson(json["_id"]),
        userId: json["userId"],
        username: json["username"],
        noOfDynStocksOwned: json["noOfDynStocksOwned"],
        noOfTransactionsMade: json["noOfTransactionsMade"],
        netReturns: json["netReturns"],
        dynStocks: dynStockFromJson(json["dynStocks"]),
      );
    }
  }

  Map<String, dynamic> toJson() => {
        "_id": id.toJson(),
        "userId": userId,
        "username": username,
        "noOfDynStocksOwned": noOfDynStocksOwned,
        "noOfTransactionsMade": noOfTransactionsMade,
        "netReturns": netReturns,
        "dynStocks": dynStocks,
      };
}

class Id {
  Id({
    required this.oid,
  });

  String oid;

  factory Id.fromJson(Map<String, dynamic> json) => Id(
        oid: json["\u0024oid"],
      );

  Map<String, dynamic> toJson() => {
        "\u0024oid": oid,
      };
}
