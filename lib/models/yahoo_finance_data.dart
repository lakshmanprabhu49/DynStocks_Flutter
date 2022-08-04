import 'package:yahoofin/yahoofin.dart';

class TickerData {
  StockInfo stockInfo;
  StockQuote price;
  StockQuote priceChange;
  double currentLocalMaximumPrice = 0.0;
  double currentLocalMinimumPrice = 0.0;

  TickerData({
    required this.stockInfo,
    required this.price,
    required this.priceChange,
  });
}
