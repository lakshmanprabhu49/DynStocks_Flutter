import 'package:dynstocks/models/bar_chart.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class TransactionsTodayBarChart extends StatelessWidget {
  List<Transaction>? transactionsToday = [];
  List<charts.Series<ITransactionsBarChart, String>> barChartsRenderData = [];
  Size screenSize;
  TransactionsTodayBarChart(
      {Key? key,
      required this.transactionsToday,
      required this.barChartsRenderData,
      required this.screenSize})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (transactionsToday != null && transactionsToday!.isNotEmpty) {
      return (Container(
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        height: screenSize.height * 0.6,
        child: charts.BarChart(
          barChartsRenderData,
          barRendererDecorator: charts.BarLabelDecorator(
              labelPosition: charts.BarLabelPosition.outside),
          animate: true,
          domainAxis: charts.OrdinalAxisSpec(
            renderSpec: charts.SmallTickRendererSpec(
                labelStyle: charts.TextStyleSpec(
                    color: charts.ColorUtil.fromDartColor(
                        Color.fromRGBO(7, 93, 141, 1)),
                    fontSize: 15,
                    fontFamily: 'Arial',
                    fontWeight: '500')),
          ),
          primaryMeasureAxis: charts.NumericAxisSpec(
              renderSpec: charts.SmallTickRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                      color: charts.ColorUtil.fromDartColor(
                          Color.fromRGBO(7, 93, 141, 1)),
                      fontSize: 15,
                      fontWeight: 'bold')),
              viewport: charts.NumericExtents.fromValues(
                  [-100, -75, -50, 0, 50, 100])),
        ),
      ));
    } else if (transactionsToday != null && transactionsToday!.isEmpty) {
      return (Container(
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        height: screenSize.height * 0.6,
        child: Align(
            alignment: Alignment.center,
            child: Text(
              'No transactions made today',
              style: GoogleFonts.lusitana(
                  color: AccentColors.yellow1,
                  fontSize: 40,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
      ));
    } else {
      return (Container(
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        height: screenSize.height * 0.6,
        child: Align(
            alignment: Alignment.center,
            child: Text(
              'Loading today\'s transactions ...',
              style: GoogleFonts.lusitana(
                  color: AccentColors.blue1,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
      ));
    }
  }
}
