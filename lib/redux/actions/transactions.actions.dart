import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/transactions.dart';

class GetAllTransactionsAction {
  String userId;
  String date;
  int limit = 0;
  int offset = 0;
  String sortDirection = ESortDirection.DESC.name;
  String sortCriterion = ESortCriterion.TransactionTime.name;
  String dynStockId = '';
  String filterCriterionStocks = '';
  String filterCriterionDay = '';
  GetAllTransactionsAction(
      {required this.userId,
      required this.date,
      this.limit = 0,
      this.offset = 0,
      this.sortCriterion = 'DESC',
      this.sortDirection = 'TransactionTime',
      this.dynStockId = '',
      this.filterCriterionStocks = '',
      this.filterCriterionDay = ''});
}

class GetAllTransactionsSuccessAction {
  final TransactionsResponse data;
  GetAllTransactionsSuccessAction({required this.data});
}

class GetAllTransactionsFailAction {
  final dynamic error;
  GetAllTransactionsFailAction({required this.error});
}

class CreateTransactionAction {
  String userId;
  String dynStockId;
  String stockCode;
  String instrumentToken;
  TransactionBody body;
  String stockOrderType = EStockOrderType.Market.name;
  CreateTransactionAction(
      {required this.userId,
      required this.instrumentToken,
      required this.dynStockId,
      required this.stockCode,
      required this.body,
      required this.stockOrderType});
}

class CreateTransactionSuccessAction {
  final Transaction transaction;
  CreateTransactionSuccessAction({required this.transaction});
}

class CreateTransactionFailAction {
  final dynamic error;
  CreateTransactionFailAction({required this.error});
}
