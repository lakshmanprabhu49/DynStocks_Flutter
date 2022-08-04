// ignore_for_file: constant_identifier_names

import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/common.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ILabelValue {
  String label = '';
  String value = '';
}

class TransactionsSortCriterion extends StatefulWidget {
  Size screenSize;
  StringCallback sortCriterionCallback;
  StringCallback sortDirectionCallback;
  TransactionsSortCriterion(
      {Key? key,
      required this.screenSize,
      required this.sortCriterionCallback,
      required this.sortDirectionCallback})
      : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _SortCriterionState createState() => _SortCriterionState(
      screenSize: screenSize,
      sortCriterionCallback: sortCriterionCallback,
      sortDirectionCallback: sortDirectionCallback);
}

class _SortCriterionState extends State<TransactionsSortCriterion> {
  Size screenSize;
  _SortCriterionState(
      {Key? key,
      required this.screenSize,
      required this.sortCriterionCallback,
      required this.sortDirectionCallback});
  Map<ESortCriterion, String> sortCriterionMap = Map();
  ESortCriterion currentSortCriterion = ESortCriterion.TransactionTime;
  ESortDirection currentSortDirection = ESortDirection.ASC;

  StringCallback sortCriterionCallback;
  StringCallback sortDirectionCallback;
  @override
  void initState() {
    super.initState();
    sortCriterionMap[ESortCriterion.TransactionTime] = 'Transaction Time';
    sortCriterionMap[ESortCriterion.StockCode] = 'Stock Code';
    sortCriterionMap[ESortCriterion.TransactionType] = 'Transaction Type';
    sortCriterionMap[ESortCriterion.ReturnAmount] = 'Return Amount';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          child: Text(
            'Sort by',
            style: GoogleFonts.overlock(
              color: PaletteColors.blue2,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
            width: screenSize.width * 0.6,
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(
                color: PaletteColors.blue3,
                borderRadius: BorderRadius.circular(10)),
            child: DropdownButton(
                style: GoogleFonts.overlock(
                    color: PaletteColors.purple1,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                isExpanded: true,
                alignment: AlignmentDirectional.center,
                dropdownColor: PaletteColors.blue3,
                value: currentSortCriterion.toString(),
                items: sortCriterionMap.entries.map((e) {
                  return DropdownMenuItem<String>(
                      value: e.key.toString(),
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                      ));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    currentSortCriterion = ESortCriterion.values.firstWhere(
                        (element) => element.toString() == newValue);
                  });
                  sortCriterionCallback(newValue.toString());
                })),
        Container(
          child: Column(children: [
            Container(
                margin: EdgeInsets.only(left: 20),
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: currentSortDirection == ESortDirection.ASC
                        ? PaletteColors.blue2
                        : Colors.white),
                child: InkWell(
                    onTap: (() {
                      setState(() {
                        currentSortDirection = ESortDirection.ASC;
                      });
                      sortDirectionCallback('${ESortDirection.ASC}');
                    }),
                    child: Text(
                      'ASC',
                      style: GoogleFonts.overlock(
                        color: currentSortDirection == ESortDirection.ASC
                            ? PaletteColors.blue3
                            : (PaletteColors.blue2),
                        fontSize: 15,
                      ),
                    ))),
            Container(
                margin: EdgeInsets.only(left: 20),
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: currentSortDirection == ESortDirection.DESC
                        ? PaletteColors.blue2
                        : Colors.white),
                child: InkWell(
                    onTap: (() {
                      setState(() {
                        currentSortDirection = ESortDirection.DESC;
                      });
                      sortDirectionCallback('${ESortDirection.DESC}');
                    }),
                    child: Text(
                      'DESC',
                      style: GoogleFonts.overlock(
                        color: currentSortDirection == ESortDirection.DESC
                            ? PaletteColors.blue3
                            : (PaletteColors.blue2),
                        fontSize: 15,
                      ),
                    ))),
          ]),
        )
      ],
    ));
  }
}
