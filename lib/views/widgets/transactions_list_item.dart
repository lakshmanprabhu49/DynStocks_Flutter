import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionsListItem extends StatelessWidget {
  Transaction transaction;
  Size screenSize;
  TransactionsListItem(
      {Key? key, required this.transaction, required this.screenSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime transactionTimeUTC = DateTime.fromMicrosecondsSinceEpoch(
        transaction.transactionTime.date * 1000,
        isUtc: true);
    DateTime transactionTimeIST =
        transactionTimeUTC.add(const Duration(seconds: 19800));
    String transactionTime =
        '${transactionTimeIST.day}-${transactionTimeIST.month}-${transactionTimeIST.year}';
    String minuteZeroAdder = transactionTimeIST.minute <= 10 ? '0' : '';
    String hour12 = transactionTimeIST.hour <= 12
        ? transactionTimeIST.hour.toString()
        : (transactionTimeIST.hour - 12).toString();
    String timePostFix = transactionTimeIST.hour <= 12 ? 'AM' : 'PM';
    transactionTime +=
        '       $hour12:$minuteZeroAdder${transactionTimeIST.minute} $timePostFix';
    return (Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.175,
        padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(25)),
            gradient: LinearGradient(colors: [
              PaletteColors.blue2,
              PaletteColors.blue1,
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              transactionTime,
              style: GoogleFonts.stardosStencil(
                color: PaletteColors.blue3,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              height: screenSize.height * 0.1,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              margin: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PaletteColors.green2, width: 4)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          transaction.stockCode,
                          style: GoogleFonts.roboto(
                              color: PaletteColors.blue2,
                              fontSize: 25,
                              fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              'Transaction Type : ',
                              style: GoogleFonts.roboto(
                                  color: PaletteColors.blue1),
                            ),
                            Text(transaction.type,
                                style: GoogleFonts.roboto(
                                  color: transaction.type == 'SELL'
                                      ? AccentColors.green1
                                      : AccentColors.red1,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        )
                      ],
                    )),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 20, 5),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.currency_rupee,
                                    size: 15, color: PaletteColors.blue2),
                                Text(
                                  '${transaction.stockPrice} * ${transaction.noOfStocks}',
                                  style: GoogleFonts.roboto(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: PaletteColors.blue2),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.currency_rupee,
                                  color: transaction.type == 'SELL'
                                      ? AccentColors.green1
                                      : AccentColors.red1,
                                ),
                                Text(
                                  transaction.amount.toString(),
                                  style: GoogleFonts.roboto(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: transaction.type == 'SELL'
                                        ? AccentColors.green1
                                        : AccentColors.red1,
                                  ),
                                )
                              ],
                            )
                          ]),
                    )
                  ]),
            )
          ],
        )));
  }
}
