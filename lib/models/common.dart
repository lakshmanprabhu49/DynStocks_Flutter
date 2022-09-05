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

enum EStockTradeStatus { TRAD, OPN, OPF, CANC }

Map<String, bool> pauseTransactions = Map();
