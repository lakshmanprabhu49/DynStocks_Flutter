import 'package:charts_flutter/flutter.dart' as charts;

class ITransactionsBarChart {
  int id;
  String time;
  double percentage;
  double amount;
  charts.Color color;
  charts.Color labelColor;

  ITransactionsBarChart(
      {required this.id,
      required this.time,
      required this.percentage,
      required this.color,
      required this.labelColor,
      this.amount = 0.0});
}

class IStockPriceLineChart {
  int id;
  num time;
  double stockPrice;
  charts.Color color;
  charts.Color labelColor;
  IStockPriceLineChart({
    required this.id,
    required this.time,
    required this.stockPrice,
    required this.color,
    required this.labelColor,
  });
}
