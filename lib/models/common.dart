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

enum EPositions { TODAYS, OPEN, STOCKS }

enum EStockType { EQ, BE, BL, BT, BZ, GZ, IL }

enum EExchange { NSE, BSE }
