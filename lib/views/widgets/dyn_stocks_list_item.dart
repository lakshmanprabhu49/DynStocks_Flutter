import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/views/screens/view_specific_dyn_stock_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DynStocksListItem extends StatelessWidget {
  DynStock dynStock;
  Size screenSize;
  DynStocksListItem(
      {Key? key, required this.dynStock, required this.screenSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenSize.width * 0.8,
      height: screenSize.height * 0.125,
      margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: PaletteColors.green2, width: 4)),
      padding: EdgeInsets.fromLTRB(20, 10, 15, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              '${dynStock.stockCode}',
              style: GoogleFonts.outfit(
                color: PaletteColors.blue2,
                fontSize: 35 /
                    int.parse((1 + (dynStock.stockCode.length / 5).toInt())
                        .toString()),
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
        Container(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(
              children: [
                Row(children: [
                  Text(
                    '${dynStock.noOfStocks}',
                    style: GoogleFonts.outfit(
                        color: PaletteColors.blue1,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' Stocks',
                    style: GoogleFonts.outfit(
                      color: PaletteColors.blue1,
                      fontSize: 15,
                    ),
                  )
                ])
              ],
            ),
            Row(children: [
              Text(
                '${dynStock.transactions.length}',
                style: GoogleFonts.outfit(
                    fontSize: 25,
                    color: PaletteColors.purple1,
                    fontWeight: FontWeight.bold),
              ),
              Text(' Transactions',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: PaletteColors.purple1,
                  ))
            ])
          ]),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: TextButton(
            child: Icon(
              Icons.arrow_back,
              size: 30,
              color: Colors.black,
              textDirection: TextDirection.rtl,
            ),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ViewSpecificDynStockScreen(
                            currentDynStockCode: dynStock.stockCode,
                          )));
            },
          ),
        )
      ]),
    );
  }
}
