import 'package:yahoofin/yahoofin.dart';

class TickerData {
  StockInfo stockInfo;
  StockQuote price;
  StockQuote priceChange;
  StockHistory? hist;
  StockChart? chart;
  double currentLocalMaximumPrice = double.negativeInfinity;
  double currentLocalMinimumPrice = double.infinity;

  TickerData({
    required this.stockInfo,
    required this.price,
    required this.priceChange,
    this.hist,
    this.chart,
  });
}
