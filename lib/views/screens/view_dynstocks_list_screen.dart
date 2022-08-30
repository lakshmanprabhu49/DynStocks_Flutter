import 'dart:async';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/redux/state/dyn_stocks.state.dart';
import 'package:dynstocks/static/toast_message_handler.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/widgets/bottom_navigation_bar_custom.dart';
import 'package:dynstocks/views/widgets/dyn_stocks_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock/wakelock.dart';

class ViewDynStocksListScreen extends StatefulWidget {
  const ViewDynStocksListScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _ViewDynStocksListScreenState createState() =>
      _ViewDynStocksListScreenState();
}

class _ViewDynStocksListScreenState extends State<ViewDynStocksListScreen>
    with RouteAware {
  String userId = appStore.state.userId;
  String searchStocksInput = '';
  bool isTimedTickerFetchStarted = false;
  bool errorMessageShown = false;
  bool reload = false;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    super.initState();
    userId = appStore.state.userId;
    searchStocksInput = '';
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
        .dispatch(GetAllDynStocksAction(userId: userId));

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
    Wakelock.enabled.then((value) {
      if (!value) {
        Wakelock.enable();
      }
    });
    DateTime now = DateTime.now();
    if ((now.hour < 9) || (now.hour == 9 && now.hour < 15)) {
      Timer.periodic(Duration(seconds: 1), (timer) {
        DateTime currentTime = DateTime.now();
        if (currentTime.hour == 9 && now.hour >= 15) {
          setState(() {
            reload = true;
          });
          timer.cancel();
        }
      });
    }
    Size screenSize = MediaQuery.of(context).size;
    if (appStore.state.allDynStocks.loadFailed && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.allDynStocks.error.message}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    if (appStore.state.allTransactions.createFailed && !errorMessageShown) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  margin: EdgeInsets.fromLTRB(10, 30, 10, 0),
                  child: Container(
                    child: Text('View your DynStocks',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            color: PaletteColors.blue2,
                            fontSize: 33,
                            fontWeight: FontWeight.bold)),
                  )),
              Container(
                margin: EdgeInsets.fromLTRB(10, 5, 10, 0),
                child: Container(
                  margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                  padding: EdgeInsets.fromLTRB(15, 5, 15, 0),
                  width: screenSize.width * 0.8,
                  height: 50,
                  decoration: BoxDecoration(
                      color: PaletteColors.blue3,
                      borderRadius: BorderRadius.circular(20)),
                  child: TextField(
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
                        searchStocksInput = value;
                      });
                    }),
                  ),
                ),
              ),
              Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Container(
                      margin: EdgeInsets.fromLTRB(10, 5, 10, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            style: ButtonStyle(
                                surfaceTintColor: MaterialStateProperty.all(
                                    Colors.transparent),
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.transparent)),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_left,
                                    size: 30, color: Colors.black),
                                Text(
                                  'Filter',
                                  style: GoogleFonts.overlock(
                                      fontSize: 20, color: Colors.black),
                                )
                              ],
                            ),
                            onPressed: () {},
                          ),
                          TextButton(
                            style: ButtonStyle(
                                surfaceTintColor: MaterialStateProperty.all(
                                    Colors.transparent),
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.transparent)),
                            child: Row(
                              children: [
                                Text(
                                  'Sort',
                                  style: GoogleFonts.overlock(
                                      fontSize: 20, color: Colors.black),
                                ),
                                Icon(Icons.arrow_right,
                                    size: 30, color: Colors.black),
                              ],
                            ),
                            onPressed: () {},
                          )
                        ],
                      ))),
              Expanded(
                  child: Container(
                margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                width: screenSize.width,
                padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                    gradient: LinearGradient(
                        colors: [PaletteColors.blue1, PaletteColors.blue2],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)),
                child: Container(
                    child: StoreConnector<AppState, DynStocksState>(
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
                          if (appStore.state.allTransactions.createFailed &&
                              !errorMessageShown) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  ToastMessageHandler.showErrorMessageSnackBar(
                                      '${appStore.state.allTransactions.error.message}'));
                            });
                            setState(() {
                              errorMessageShown = true;
                            });
                          }
                        },
                        converter: ((store) => store.state.allDynStocks),
                        builder: (context, allDynStocksState) {
                          if (allDynStocksState.loadFailed) {
                            return Text(
                              allDynStocksState.error.toString(),
                              style: GoogleFonts.lusitana(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            );
                          } else if (allDynStocksState.loaded &&
                              !allDynStocksState.loading) {
                            List<DynStock> sortedDynStocks =
                                allDynStocksState.data;
                            if (searchStocksInput.isNotEmpty) {
                              sortedDynStocks = sortedDynStocks
                                  .where((element) => element.stockCode
                                      .toLowerCase()
                                      .contains(
                                          searchStocksInput.toLowerCase()))
                                  .toList();
                            }
                            if (sortedDynStocks.isNotEmpty) {
                              return Container(
                                  child: ListView.builder(
                                      itemCount: sortedDynStocks.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return DynStocksListItem(
                                            dynStock: sortedDynStocks[index],
                                            screenSize: screenSize);
                                      }));
                            } else {
                              return Text(
                                'No DynStocks match your search criteria',
                                style: GoogleFonts.lusitana(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              );
                            }
                          } else if (allDynStocksState.loading) {
                            return Text(
                              'Loading list of DynStocks ...',
                              style: GoogleFonts.lusitana(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            );
                          }
                          return Text('Hi');
                        })),
              ))
            ],
          )),
      bottomNavigationBar: BottomNavigationBarCustom(
        screenSize: screenSize,
        selectedIndex: 1,
      ),
    );
  }
}
