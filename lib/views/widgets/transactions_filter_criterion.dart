// ignore_for_file: constant_identifier_names

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionsFilterCriterion extends StatefulWidget {
  Size screenSize;
  StringCallback stocksFilterCallback;
  StringCallback daysFilterCallback;
  StringCallback stocksFilterCustomInputCallback;
  String customStockCode = '';
  TransactionsFilterCriterion(
      {Key? key,
      required this.screenSize,
      required this.stocksFilterCallback,
      required this.stocksFilterCustomInputCallback,
      required this.daysFilterCallback,
      this.customStockCode = ''})
      : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _FilterCriterionState createState() => _FilterCriterionState(
      screenSize: screenSize,
      stocksFilterCallback: stocksFilterCallback,
      stocksFilterCustomInputCallback: stocksFilterCustomInputCallback,
      daysFilterCallback: daysFilterCallback,
      customStockCode: customStockCode);
}

class _FilterCriterionState extends State<TransactionsFilterCriterion> {
  Size screenSize;
  EStocksFilterCriterion currentStocksFilterCriterion =
      EStocksFilterCriterion.All;
  EDaysFilterCriterion currentDaysFilterCriterion = EDaysFilterCriterion.All;
  String currentStocksCustomInput = '';

  StringCallback stocksFilterCallback;
  StringCallback daysFilterCallback;
  StringCallback stocksFilterCustomInputCallback;

  String customStockCode = '';
  _FilterCriterionState(
      {Key? key,
      required this.screenSize,
      required this.stocksFilterCallback,
      required this.stocksFilterCustomInputCallback,
      required this.daysFilterCallback,
      this.customStockCode = ''});

  @override
  void initState() {
    super.initState();
    if (customStockCode.isEmpty) {
      currentStocksFilterCriterion = EStocksFilterCriterion.All;
    } else {
      currentStocksFilterCriterion = EStocksFilterCriterion.Custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: screenSize.width * 0.9,
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25), color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                child: Text(
              'Filter by',
              style: GoogleFonts.overlock(
                  color: PaletteColors.blue2,
                  fontWeight: FontWeight.bold,
                  fontSize: 23),
            )),
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(0, 15, 0, 0),
                  child: Text(
                    'Stocks: ',
                    style: GoogleFonts.overlock(
                      color: PaletteColors.blue2,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                    margin: EdgeInsets.fromLTRB(20, 15, 0, 0),
                    child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              margin: EdgeInsets.only(left: 20),
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: currentStocksFilterCriterion ==
                                          EStocksFilterCriterion.All
                                      ? PaletteColors.blue2
                                      : Colors.white),
                              child: InkWell(
                                  onTap: (() {
                                    if (customStockCode.isEmpty) {
                                      setState(() {
                                        currentStocksFilterCriterion =
                                            EStocksFilterCriterion.All;
                                      });
                                      stocksFilterCallback(
                                          '${EStocksFilterCriterion.All}');
                                    }
                                  }),
                                  child: Text(
                                    'All',
                                    style: GoogleFonts.overlock(
                                      color: currentStocksFilterCriterion ==
                                              EStocksFilterCriterion.All
                                          ? PaletteColors.blue3
                                          : (PaletteColors.blue2),
                                      fontSize: 20,
                                    ),
                                  ))),
                          Container(
                              margin: EdgeInsets.only(left: 20),
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: currentStocksFilterCriterion ==
                                          EStocksFilterCriterion.Custom
                                      ? PaletteColors.blue2
                                      : Colors.white),
                              child: InkWell(
                                  onTap: (() {
                                    if (customStockCode.isEmpty) {
                                      setState(() {
                                        currentStocksFilterCriterion =
                                            EStocksFilterCriterion.Custom;
                                      });
                                      stocksFilterCallback(
                                          '${EStocksFilterCriterion.Custom}');
                                    }
                                  }),
                                  child: Text(
                                    'Custom',
                                    style: GoogleFonts.overlock(
                                      color: currentStocksFilterCriterion ==
                                              EStocksFilterCriterion.Custom
                                          ? PaletteColors.blue3
                                          : (PaletteColors.blue2),
                                      fontSize: 20,
                                    ),
                                  )))
                        ])),
              ],
            ),
            if (currentStocksFilterCriterion == EStocksFilterCriterion.Custom)
              // TODO: Dropdown multi select for all the stock codes
              (Container(
                margin: EdgeInsets.fromLTRB(10, 5, 10, 0),
                child: Container(
                  margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                  padding: EdgeInsets.fromLTRB(15, 5, 15, 0),
                  width: screenSize.width * 0.8,
                  height: 50,
                  decoration: BoxDecoration(
                      color: PaletteColors.blue3,
                      borderRadius: BorderRadius.circular(20)),
                  child: TextFormField(
                    initialValue: customStockCode,
                    readOnly: customStockCode.isNotEmpty,
                    decoration: InputDecoration(
                        hintText: 'Search DynStocks',
                        hintStyle: GoogleFonts.overlock(
                            color: PaletteColors.blue4, fontSize: 20),
                        fillColor: PaletteColors.blue3,
                        suffixIcon: Icon(
                          Icons.search_sharp,
                          size: 25,
                        )),
                    style: GoogleFonts.overlock(
                        color: PaletteColors.blue2, fontSize: 20),
                    onChanged: ((value) {
                      setState(() {
                        currentStocksCustomInput = value;
                      });
                      stocksFilterCustomInputCallback(
                          '${currentStocksCustomInput}');
                    }),
                  ),
                ),
              )),
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(0, 15, 0, 0),
                  child: Text(
                    'Days: ',
                    style: GoogleFonts.overlock(
                      color: PaletteColors.blue2,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                    margin: EdgeInsets.fromLTRB(20, 15, 0, 0),
                    child: Row(children: [
                      Container(
                          margin: EdgeInsets.only(left: 20),
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: currentDaysFilterCriterion ==
                                      EDaysFilterCriterion.All
                                  ? PaletteColors.blue2
                                  : Colors.white),
                          child: InkWell(
                              onTap: (() {
                                StoreProvider.of<AppState>(context).dispatch(
                                    GetAllTransactionsAction(
                                        userId: appStore.state.userId,
                                        date: ''));
                                setState(() {
                                  currentDaysFilterCriterion =
                                      EDaysFilterCriterion.All;
                                });
                                daysFilterCallback(
                                    '${EDaysFilterCriterion.All}');
                              }),
                              child: Text(
                                'All',
                                style: GoogleFonts.overlock(
                                  color: currentDaysFilterCriterion ==
                                          EDaysFilterCriterion.All
                                      ? PaletteColors.blue3
                                      : (PaletteColors.blue2),
                                  fontSize: 20,
                                ),
                              ))),
                      Container(
                          margin: EdgeInsets.only(left: 20),
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: currentDaysFilterCriterion ==
                                      EDaysFilterCriterion.Today
                                  ? PaletteColors.blue2
                                  : Colors.white),
                          child: InkWell(
                              onTap: (() {
                                DateTime now = DateTime.now();
                                String formattedDate =
                                    DateFormat('MMM dd yyyy').format(now);
                                StoreProvider.of<AppState>(context).dispatch(
                                    GetAllTransactionsAction(
                                        userId: appStore.state.userId,
                                        date: formattedDate));
                                setState(() {
                                  currentDaysFilterCriterion =
                                      EDaysFilterCriterion.Today;
                                });
                                daysFilterCallback(
                                    '${EDaysFilterCriterion.Today}');
                              }),
                              child: Text(
                                'Today',
                                style: GoogleFonts.overlock(
                                  color: currentDaysFilterCriterion ==
                                          EDaysFilterCriterion.Today
                                      ? PaletteColors.blue3
                                      : (PaletteColors.blue2),
                                  fontSize: 20,
                                ),
                              ))),
                      Container(
                          margin: EdgeInsets.only(left: 20),
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: currentDaysFilterCriterion ==
                                      EDaysFilterCriterion.Custom
                                  ? PaletteColors.blue2
                                  : Colors.white),
                          child: InkWell(
                              onTap: (() {
                                setState(() {
                                  currentDaysFilterCriterion =
                                      EDaysFilterCriterion.Custom;
                                });
                                daysFilterCallback(
                                    '${EDaysFilterCriterion.Custom}');
                              }),
                              child: Text(
                                'Custom',
                                style: GoogleFonts.overlock(
                                  color: currentDaysFilterCriterion ==
                                          EDaysFilterCriterion.Custom
                                      ? PaletteColors.blue3
                                      : (PaletteColors.blue2),
                                  fontSize: 20,
                                ),
                              ))),
                    ])),
              ],
            ),
            if (currentDaysFilterCriterion == EDaysFilterCriterion.Custom)
              // TODO: Date single select for all LOVs
              (Container(
                width: screenSize.width * 0.9,
                child: Text('Custom'),
              )),
          ],
        ));
  }
}
