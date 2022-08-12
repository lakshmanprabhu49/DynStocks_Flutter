import 'dart:async';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/transactions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/redux/state/transactions.state.dart';
import 'package:dynstocks/static/toast_message_handler.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/widgets/transactions_filter_criterion.dart';
import 'package:dynstocks/views/widgets/transactions_list_item.dart';
import 'package:dynstocks/views/widgets/transactions_sort_criterion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redux/redux.dart';

class ViewTransactionsScreen extends StatefulWidget {
  final String customStockCode;
  const ViewTransactionsScreen({Key? key, required this.customStockCode})
      : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _ViewTransactionsScreenState createState() => _ViewTransactionsScreenState(
        customStockCode: customStockCode,
      );
}

class _ViewTransactionsScreenState extends State<ViewTransactionsScreen>
    with RouteAware {
  _ViewTransactionsScreenState({required this.customStockCode});
  String dynStockId = '';
  DateTime transactionDate = DateTime.now();
  bool isTimedTickerFetchStarted = false;
  String userId = appStore.state.userId;
  EStocksFilterCriterion currentStocksFilterCriterion =
      EStocksFilterCriterion.All;
  EDaysFilterCriterion currentDaysFilterCriterion = EDaysFilterCriterion.All;
  String currentStocksCustomInput = '';
  ESortCriterion currentSortCriterion = ESortCriterion.TransactionTime;
  ESortDirection currentSortDirection = ESortDirection.DESC;
  bool errorMessageShown = false;
  String customStockCode;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    super.initState();
    userId = appStore.state.userId;
    if (mounted) {
      if (customStockCode.isEmpty) {
        setState(() {
          currentStocksFilterCriterion = EStocksFilterCriterion.All;
        });
      } else {
        setState(() {
          currentStocksFilterCriterion = EStocksFilterCriterion.Custom;
        });
      }
      setState(() {
        currentStocksCustomInput = customStockCode;
      });
    }
  }

  // This function starts the periodic timer for the ticker data action
  // If the ticker timer hasn't started , there is an explicit timer for the screen which runs,
  // till the ticker timer is started
  void startPeriodicTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        bool timerStarted = TimedTickerCall?.startTimedTickerCallForDynStocks(
          context,
        );
        if (timerStarted) {
          setState(() {
            isTimedTickerFetchStarted = true;
          });
          timer.cancel();
        }
      }
    });
  }

  // Stops the periodic timer, possibly invoked when the screen goes out of focus
  void stopPeriodicTimer() {
    TimedTickerCall.stopTimedTickerCallForDynStocks();
  }

  @override
  void didPop() {
    stopPeriodicTimer();
    super.didPop();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    startPeriodicTimer();
  }

  @override
  void didPush() {
    super.didPush();
    StoreProvider.of<AppState>(context)
        .dispatch(GetAllTransactionsAction(userId: userId, date: ''));
    setState(() {
      errorMessageShown = false;
    });
    startPeriodicTimer();
  }

  @override
  void didPushNext() {
    stopPeriodicTimer();
    super.didPushNext();
  }

  @override
  void dispose() {
    stopPeriodicTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    if (appStore.state.allTransactions.loadFailed && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.allTransactions.error.message}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            width: screenSize.width,
            height: screenSize.height,
            decoration: BoxDecoration(color: Colors.white),
            child: Column(children: [
              Container(
                  decoration: BoxDecoration(
                      color: PaletteColors.blue2,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(75),
                        bottomRight: Radius.circular(75),
                      )),
                  child: Container(
                      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: Column(children: [
                        Row(
                          children: [
                            Flexible(
                                flex: 1,
                                child: Container(
                                    margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: ButtonTheme(
                                        height: 25,
                                        minWidth: 25,
                                        child: TextButton(
                                          style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.transparent),
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.transparent)),
                                          child: Icon(
                                            Icons.arrow_back,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        )))),
                            Flexible(
                                flex: 3,
                                child: Container(
                                  margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Text(
                                      customStockCode.isEmpty
                                          ? 'View all Transactions'
                                          : 'Transactions - ${customStockCode}',
                                      style: GoogleFonts.overlock(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold)),
                                ))
                          ],
                        ),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
                            child: TransactionsFilterCriterion(
                              screenSize: screenSize,
                              stocksFilterCallback: (String newStocksFilter) {
                                setState(() {
                                  currentStocksFilterCriterion =
                                      EStocksFilterCriterion.values.firstWhere(
                                          (e) =>
                                              e.toString() == newStocksFilter);
                                  currentStocksCustomInput =
                                      newStocksFilter.contains('All')
                                          ? ''
                                          : currentStocksCustomInput;
                                });
                              },
                              daysFilterCallback: (String newDaysFilter) {
                                setState(() {
                                  currentDaysFilterCriterion =
                                      EDaysFilterCriterion.values.firstWhere(
                                          (e) => e.toString() == newDaysFilter);
                                });
                              },
                              stocksFilterCustomInputCallback:
                                  (String newCustomStockInput) {
                                setState(() {
                                  currentStocksCustomInput =
                                      newCustomStockInput;
                                });
                              },
                              customStockCode: customStockCode,
                            )),
                      ]))),
              Container(
                  margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: TransactionsSortCriterion(
                    screenSize: screenSize,
                    sortCriterionCallback: (String newValue) {
                      setState(() {
                        currentSortCriterion = ESortCriterion.values.firstWhere(
                            (element) => element.toString() == newValue);
                      });
                    },
                    sortDirectionCallback: (String newValue) {
                      setState(() {
                        currentSortDirection = ESortDirection.values.firstWhere(
                            (element) => element.toString() == newValue);
                      });
                    },
                  )),
              Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: StoreConnector<AppState, TransactionsState>(
                    onDidChange: (previousState, state) {
                      if (state.loadFailed && !errorMessageShown) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              ToastMessageHandler.showErrorMessageSnackBar(
                                  '${state.error.message}'));
                        });
                        setState(() {
                          errorMessageShown = true;
                        });
                      }
                    },
                    converter: ((store) => store.state.allTransactions),
                    builder: (context, allTransactionsState) {
                      if (allTransactionsState.loadFailed) {
                        return Text(
                          allTransactionsState.error.toString(),
                          style: GoogleFonts.lusitana(
                              color: AccentColors.blue1,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        );
                      } else if (allTransactionsState.loading) {
                        return Text(
                          'Loading list of transactions ...',
                          style: GoogleFonts.lusitana(
                              color: AccentColors.blue1,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        );
                      } else if (allTransactionsState.loaded &&
                          !allTransactionsState.loading) {
                        List<Transaction> sortedTransactions =
                            List.from(allTransactionsState.data);
                        sortedTransactions = sortedTransactions
                            .where((element) => element.stockCode
                                .toLowerCase()
                                .contains(
                                    currentStocksCustomInput.toLowerCase()))
                            .toList();
                        if (sortedTransactions.isEmpty) {
                          if (currentStocksCustomInput.isNotEmpty) {
                            return Container(
                                child: Text(
                              'No transactions match your search criteria',
                              style: GoogleFonts.lusitana(
                                  color: AccentColors.blue1,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ));
                          } else if (currentDaysFilterCriterion ==
                              EDaysFilterCriterion.Today) {
                            return Container(
                                child: Text(
                              'No transactions were made today',
                              style: GoogleFonts.lusitana(
                                  color: AccentColors.blue1,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ));
                          } else {
                            return Container(
                                child: Text(
                              'There are no transactions made in total',
                              style: GoogleFonts.lusitana(
                                  color: AccentColors.blue1,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ));
                          }
                        }
                        switch (currentSortCriterion) {
                          case ESortCriterion.TransactionTime:
                            sortedTransactions
                                .sort((Transaction a, Transaction b) {
                              Transaction first = a;
                              Transaction second = b;
                              if (currentSortDirection == ESortDirection.DESC) {
                                first = b;
                                second = a;
                              }
                              return first.transactionTime.date -
                                  second.transactionTime.date;
                            });
                            break;
                          case ESortCriterion.StockCode:
                            sortedTransactions
                                .sort((Transaction a, Transaction b) {
                              Transaction first = a;
                              Transaction second = b;
                              if (currentSortDirection == ESortDirection.DESC) {
                                first = b;
                                second = a;
                              }
                              return first.stockCode
                                  .compareTo(second.stockCode);
                            });
                            break;
                          case ESortCriterion.TransactionType:
                            sortedTransactions
                                .sort((Transaction a, Transaction b) {
                              Transaction first = a;
                              Transaction second = b;
                              if (currentSortDirection == ESortDirection.DESC) {
                                first = b;
                                second = a;
                              }
                              return first.type.compareTo(second.type);
                            });
                            break;
                          case ESortCriterion.ReturnAmount:
                            sortedTransactions
                                .sort((Transaction a, Transaction b) {
                              Transaction first = a;
                              Transaction second = b;
                              if (currentSortDirection == ESortDirection.DESC) {
                                first = b;
                                second = a;
                              }
                              return (first.amount - second.amount).toInt();
                            });
                            break;
                        }
                        return Column(children: [
                          Text(
                              'No of transactions: ${sortedTransactions.length}',
                              style: GoogleFonts.actor(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: PaletteColors.purple1)),
                          Container(
                              height: (currentStocksFilterCriterion ==
                                      EStocksFilterCriterion.All
                                  ? screenSize.height * 0.5
                                  : screenSize.height * 0.4),
                              child: (ListView.builder(
                                  itemCount: sortedTransactions.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Container(
                                        margin:
                                            EdgeInsets.fromLTRB(0, 15, 0, 15),
                                        child: TransactionsListItem(
                                            screenSize: screenSize,
                                            transaction:
                                                sortedTransactions[index]));
                                  })))
                        ]);
                      }
                      return Text('Store is empty: $userId');
                    },
                  ))
            ])));
  }
}
