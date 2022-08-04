import 'package:dynstocks/models/yahoo_finance_data.dart';

class GetAllTickerDataAction {
  GetAllTickerDataAction();
}

class GetAllTickerDataSuccessAction {
  final Map<String, TickerData> allTickerData;
  GetAllTickerDataSuccessAction({required this.allTickerData});
}

class GetAllTickerDataFailAction {
  final dynamic error;
  GetAllTickerDataFailAction({required this.error});
}
