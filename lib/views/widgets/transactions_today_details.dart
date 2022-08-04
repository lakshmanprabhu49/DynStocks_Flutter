import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TransactionsTodayDetails extends StatelessWidget {
  double maxTradedAmount = 0.0;
  Map<String, int> noOfStocks = Map();
  double netReturnsToday = 0.0;
  Size screenSize;
  TransactionsTodayDetails({
    required this.maxTradedAmount,
    required this.noOfStocks,
    required this.netReturnsToday,
    required this.screenSize,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
                key: Key("Maximum Traded Price"),
                child: Container(
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    height: screenSize.height * 0.08,
                    width: screenSize.width * 0.9,
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    decoration: BoxDecoration(
                        border:
                            Border.all(width: 4, color: PaletteColors.green2),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: PaletteColors.blue2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.money,
                          color: AccentColors.yellow2,
                          size: 30,
                        ),
                        Text(
                          'Maximum Traded Price',
                          style: GoogleFonts.lusitana(
                              color: PaletteColors.blue3, fontSize: 17),
                        ),
                        Container(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                              Icon(
                                Icons.currency_rupee,
                                color: PaletteColors.blue3,
                              ),
                              Text(
                                maxTradedAmount.toString(),
                                style: GoogleFonts.lusitana(
                                    color: PaletteColors.blue3,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              )
                            ]))
                      ],
                    ))),
            Flexible(
                key: Key("No of Stocks Traded"),
                child: Container(
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    height: screenSize.height * 0.08,
                    width: screenSize.width * 0.9,
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    decoration: BoxDecoration(
                        border:
                            Border.all(width: 4, color: PaletteColors.green2),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: PaletteColors.blue2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: AccentColors.blue2,
                          size: 30,
                        ),
                        Text(
                          'No of Stocks Traded',
                          style: GoogleFonts.lusitana(
                              color: PaletteColors.blue3, fontSize: 17),
                        ),
                        Container(
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                              Container(
                                  margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(noOfStocks['BUY'].toString(),
                                          style: GoogleFonts.lora(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            color: AccentColors.red2,
                                          )),
                                      Text(
                                        '(BUY)',
                                        style: GoogleFonts.lora(
                                          color: PaletteColors.blue4,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )),
                              Container(
                                  margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(noOfStocks['SELL'].toString(),
                                          style: GoogleFonts.lora(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            color: AccentColors.yellow2,
                                          )),
                                      Text(
                                        '(SELL)',
                                        style: GoogleFonts.lora(
                                          fontSize: 10,
                                          color: PaletteColors.blue4,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ))
                            ]))
                      ],
                    ))),
            Flexible(
                key: Key("Net Returns"),
                child: Container(
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    height: screenSize.height * 0.08,
                    width: screenSize.width * 0.9,
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    decoration: BoxDecoration(
                        border:
                            Border.all(width: 4, color: PaletteColors.green2),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: PaletteColors.blue2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.stacked_line_chart_outlined,
                          color: AccentColors.green2,
                          size: 30,
                        ),
                        Text(
                          'Net Returns',
                          style: GoogleFonts.lusitana(
                              color: PaletteColors.blue3, fontSize: 17),
                        ),
                        Container(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                              Text(
                                netReturnsToday.toString(),
                                style: GoogleFonts.lusitana(
                                    color: PaletteColors.blue3,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              Icon(
                                Icons.currency_rupee,
                                color: PaletteColors.blue3,
                              ),
                            ]))
                      ],
                    )))
          ],
        ));
  }
}
