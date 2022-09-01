// To parse this JSON data, do
//
//     final kotakStockApiPlaceOrderResponse = kotakStockApiPlaceOrderResponseFromJson(jsonString);

import 'dart:convert';

KotakStockApiPlaceOrderResponse kotakStockApiPlaceOrderResponseFromJson(
        String str) =>
    KotakStockApiPlaceOrderResponse.fromJson(json.decode(str));

String kotakStockApiPlaceOrderResponseToJson(
        KotakStockApiPlaceOrderResponse data) =>
    json.encode(data.toJson());

class KotakStockApiPlaceOrderResponse {
  KotakStockApiPlaceOrderResponse({
    this.success,
  });

  PlaceOrderSuccess? success;

  factory KotakStockApiPlaceOrderResponse.fromJson(Map<String, dynamic> json) =>
      KotakStockApiPlaceOrderResponse(
        success: PlaceOrderSuccess.fromJson(json["Success"]),
      );

  Map<String, dynamic> toJson() => {
        "Success": success?.toJson(),
      };
}

class PlaceOrderSuccess {
  PlaceOrderSuccess({
    this.nse,
    this.bse,
  });

  PlaceOrderData? nse;
  PlaceOrderData? bse;

  factory PlaceOrderSuccess.fromJson(Map<String, dynamic> json) {
    if (json["NSE"] != null) {
      return PlaceOrderSuccess(
        nse: PlaceOrderData.fromJson(json["NSE"]),
      );
    } else {
      return PlaceOrderSuccess(
        bse: PlaceOrderData.fromJson(json["BSE"]),
      );
    }
  }

  Map<String, dynamic> toJson() => {
        "NSE": nse?.toJson(),
        "BSE": bse?.toJson(),
      };
}

class PlaceOrderData {
  PlaceOrderData({
    required this.message,
    required this.orderId,
    required this.price,
    required this.quantity,
    required this.tag,
  });

  String message;
  int orderId;
  double price;
  int quantity;
  String tag;

  factory PlaceOrderData.fromJson(Map<String, dynamic> json) => PlaceOrderData(
        message: json["message"],
        orderId: json["orderId"] as int,
        price: (json["price"]).toDouble(),
        quantity: json["quantity"] as int,
        tag: json["tag"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "orderId": orderId,
        "price": price,
        "quantity": quantity,
        "tag": tag,
      };
}

KotakStockApiPositionsResponse kotakStockApiPositionsResponseFromJson(
        String str) =>
    KotakStockApiPositionsResponse.fromJson(json.decode(str));

String kotakStockApiPositionsResponseToJson(
        KotakStockApiPositionsResponse data) =>
    json.encode(data.toJson());

class KotakStockApiPositionsResponse {
  KotakStockApiPositionsResponse({
    required this.success,
  });

  List<PositionsSuccess> success;

  factory KotakStockApiPositionsResponse.fromJson(Map<String, dynamic> json) =>
      KotakStockApiPositionsResponse(
        success: List<PositionsSuccess>.from(
            json["Success"].map((x) => PositionsSuccess.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "Success": List<dynamic>.from(success.map((x) => x.toJson())),
      };
}

class PositionsSuccess {
  PositionsSuccess({
    required this.actualNetTrdValue,
    required this.averageStockPrice,
    required this.buyTradedVal,
    required this.buyTrdAvg,
    required this.instrumentName,
    required this.instrumentToken,
    required this.lastPrice,
    required this.sellTradedQtyLot,
    required this.sellTradedVal,
    required this.sellTrdAvg,
    required this.totalStock,
  });

  double actualNetTrdValue;
  double averageStockPrice;
  double buyTradedVal;
  double buyTrdAvg;
  String instrumentName;
  int instrumentToken;
  double lastPrice;
  int sellTradedQtyLot;
  double sellTradedVal;
  double sellTrdAvg;
  int totalStock;

  factory PositionsSuccess.fromJson(Map<String, dynamic> json) =>
      PositionsSuccess(
        actualNetTrdValue: json["actualNetTrdValue"].toDouble(),
        averageStockPrice: json["averageStockPrice"].toDouble(),
        buyTradedVal: json["buyTradedVal"].toDouble(),
        buyTrdAvg: json["buyTrdAvg"].toDouble(),
        instrumentName: json["instrumentName"],
        instrumentToken: json["instrumentToken"],
        lastPrice: json["lastPrice"].toDouble(),
        sellTradedQtyLot: json["sellTradedQtyLot"],
        sellTradedVal: json["sellTradedVal"].toDouble(),
        sellTrdAvg: json["sellTrdAvg"].toDouble(),
        totalStock: json["totalStock"],
      );

  Map<String, dynamic> toJson() => {
        "actualNetTrdValue": actualNetTrdValue,
        "averageStockPrice": averageStockPrice,
        "buyTradedVal": buyTradedVal,
        "buyTrdAvg": buyTrdAvg,
        "instrumentName": instrumentName,
        "instrumentToken": instrumentToken,
        "lastPrice": lastPrice,
        "sellTradedQtyLot": sellTradedQtyLot,
        "sellTradedVal": sellTradedVal,
        "sellTrdAvg": sellTrdAvg,
        "totalStock": totalStock,
      };
}

class KotakStockAPIPlaceOrderBody {
  String orderType;
  String instrumentToken;
  String transactionType;
  int quantity;
  double? price = 0.0;

  KotakStockAPIPlaceOrderBody({
    required this.orderType,
    required this.instrumentToken,
    required this.transactionType,
    required this.quantity,
    this.price = 0.0,
  });

  factory KotakStockAPIPlaceOrderBody.fromJson(Map<String, dynamic> json) =>
      KotakStockAPIPlaceOrderBody(
        orderType: json["orderType"],
        instrumentToken: json["instrumentToken"],
        transactionType: json["transactionType"],
        quantity: json["quantity"],
        price: json["price"],
      );

  Map<String, dynamic> toJson() => {
        "orderType": orderType,
        "instrumentToken": instrumentToken,
        "transactionType": transactionType,
        "quantity": quantity,
        "price": price,
      };
}

KotakStockApiLoginResponse kotakStockApiLoginResponseFromJson(String str) =>
    KotakStockApiLoginResponse.fromJson(json.decode(str));

String kotakStockApiLoginResponseToJson(KotakStockApiLoginResponse data) =>
    json.encode(data.toJson());

class KotakStockApiLoginResponse {
  KotakStockApiLoginResponse({
    required this.message,
    required this.token,
  });

  String message;
  String token;

  factory KotakStockApiLoginResponse.fromJson(Map<String, dynamic> json) =>
      KotakStockApiLoginResponse(
        message: json["message"],
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "token": token,
      };
}

KotakStockApiOrderReportsResponse kotakStockApiOrderReportsResponseFromJson(
        String str) =>
    KotakStockApiOrderReportsResponse.fromJson(json.decode(str));

String kotakStockApiOrderReportsResponseToJson(
        KotakStockApiOrderReportsResponse data) =>
    json.encode(data.toJson());

class KotakStockApiOrderReportsResponse {
  KotakStockApiOrderReportsResponse({
    required this.success,
  });

  List<OrderReportsSuccess> success;

  factory KotakStockApiOrderReportsResponse.fromJson(
          Map<String, dynamic> json) =>
      KotakStockApiOrderReportsResponse(
        success: List<OrderReportsSuccess>.from(
            json["success"].map((x) => OrderReportsSuccess.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": List<dynamic>.from(success.map((x) => x.toJson())),
      };
}

class OrderReportsSuccess {
  OrderReportsSuccess({
    required this.exchange,
    required this.instrumentName,
    required this.instrumentToken,
    required this.instrumentType,
    required this.orderId,
    required this.price,
    required this.statusInfo,
    required this.transactionType,
    required this.orderQuantity,
    required this.pendingQuantity,
  });

  String exchange;
  String instrumentName;
  int instrumentToken;
  String instrumentType;
  int orderId;
  double price;
  String transactionType;
  String statusInfo;
  int orderQuantity;
  int pendingQuantity;

  factory OrderReportsSuccess.fromJson(Map<String, dynamic> json) =>
      OrderReportsSuccess(
        exchange: json["exchange"],
        instrumentName: json["instrumentName"],
        instrumentToken: json["instrumentToken"],
        instrumentType: json["instrumentType"],
        orderId: json["orderId"],
        price: json["price"].toDouble(),
        statusInfo: json["statusInfo"],
        transactionType: json["transactionType"],
        orderQuantity: json["orderQuantity"],
        pendingQuantity: json["pendingQuantity"],
      );

  Map<String, dynamic> toJson() => {
        "exchange": exchange,
        "instrumentName": instrumentName,
        "instrumentToken": instrumentToken,
        "instrumentType": instrumentType,
        "orderId": orderId,
        "price": price,
        "statusInfo": statusInfo,
        "transactionType": transactionType,
        "orderQuantity": orderQuantity,
        "pendingQuantity": pendingQuantity,
      };
}
