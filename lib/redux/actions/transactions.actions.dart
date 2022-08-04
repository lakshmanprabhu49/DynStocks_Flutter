import 'package:dynstocks/models/transactions.dart';

class GetAllTransactionsAction {
  String userId;
  String date;
  GetAllTransactionsAction({required this.userId, required this.date});
}

class GetAllTransactionsSuccessAction {
  final List<Transaction> allTransactions;
  GetAllTransactionsSuccessAction({required this.allTransactions});
}

class GetAllTransactionsFailAction {
  final dynamic error;
  GetAllTransactionsFailAction({required this.error});
}

class CreateTransactionAction {
  String userId;
  String dynStockId;
  String instrumentToken;
  TransactionBody body;
  CreateTransactionAction(
      {required this.userId,
      required this.instrumentToken,
      required this.dynStockId,
      required this.body});
}

class CreateTransactionSuccessAction {
  final Transaction transaction;
  CreateTransactionSuccessAction({required this.transaction});
}

class CreateTransactionFailAction {
  final dynamic error;
  CreateTransactionFailAction({required this.error});
}
