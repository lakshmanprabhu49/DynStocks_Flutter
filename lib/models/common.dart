// ignore_for_file: constant_identifier_names, prefer_generic_function_type_aliases

enum EStocksFilterCriterion { All, Custom }

enum EDaysFilterCriterion { All, Today, Custom }

typedef void StringCallback(String id);

enum ESortCriterion {
  TransactionTime,
  StockCode,
  TransactionType,
  ReturnAmount
}

enum ESortDirection {
  ASC,
  DESC,
}

enum EDSTPUnit { Price, Percentage }

enum EKotakStockOrderType {
  N,
  SOR,
  MTF,
  MIS,
}

enum EStockOrderType { Limit, Market }

enum EPositions { TODAYS, OPEN, STOCKS }

enum EStockType { EQ, BE, BL, BT, BZ, GZ, IL }

enum EExchange { NSE, BSE }

enum EChoice { Yes, No }

enum ETransactionType { BUY, SELL }

enum EStockTradeStatusInfo { Traded, Open, Partially_Traded }

extension EStockTradeStatusInfoExtension on EStockTradeStatusInfo {
  String get name {
    switch (this) {
      case EStockTradeStatusInfo.Traded:
        return 'Traded';
      case EStockTradeStatusInfo.Open:
        return 'Open';
      case EStockTradeStatusInfo.Partially_Traded:
        return 'Partially traded';
      default:
        return 'Open';
    }
  }
}
