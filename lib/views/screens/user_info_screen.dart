import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/bar_chart.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/common.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/redux/actions/authentication.actions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/local_user_creds.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/user_info.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/redux/state/dyn_stocks.state.dart';
import 'package:dynstocks/static/post-market-timer.dart';
import 'package:dynstocks/static/toast_message_handler.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/screens/enter_local_user_creds_screen.dart';
import 'package:dynstocks/views/screens/view_dynstocks_list_screen.dart';
import 'package:dynstocks/views/screens/view_transactions_screen.dart';
import 'package:dynstocks/views/widgets/bottom_navigation_bar_custom.dart';
import 'package:dynstocks/views/widgets/dyn_stocks_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'package:yahoofin/yahoofin.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'dart:math';

class UserInfoScreen extends StatefulWidget {
  UserInfoScreen({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> with RouteAware {
  _UserInfoScreenState();
  DynStock? currentDynStock;
  String username = '';
  String currentStockTimePeriod = '1d';
  bool isTimedTickerFetchStarted = false;
  List<String> stockTimePeriod =
      List.from(['1d', '1w', '1m', '3m', '6m', '1y']);

  List<FlSpot> actualStockChartPoints = [];
  List<FlSpot> dynStockChartPoints = [];
  bool isLoaded = false;
  bool errorMessageShown = false;
  bool reload = false;
  int timedTickerPeriod = 1;
  TextEditingController timedTickerPeriodController = TextEditingController();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    isLoaded = false;
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          username = prefs.getString('username') as String;
          timedTickerPeriod = prefs.getInt('timedTickerPeriod') as int;
        });
        timedTickerPeriodController = TextEditingController(
            text: (prefs.getInt('timedTickerPeriod') as int).toString());
        timedTickerPeriodController.selection = TextSelection.collapsed(
            offset: timedTickerPeriodController.text.length);
      }
    });
  }

  // This function starts the periodic timer for te ticker data action
  // If the ticker timer hasn't started , there is an explicit timer for the screen which runs,
  // till the ticker timer is started
  void startPeriodicTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        PostMarketTimer.startPostMarketTimer(context);
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

  String userId = appStore.state.userId;

  Future<String?> showLogoutDialog() {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AccentColors.red1,
          ),
        ),
        content: Text(
          'Are you sure you want to logout for this user?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AccentColors.yellow1,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                Colors.white,
              ),
            ),
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.lusitana(
                    fontSize: 15,
                    color: AccentColors.red1,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                AccentColors.red1,
              ),
            ),
            onPressed: () {
              if (mounted) {
                StoreProvider.of<AppState>(context)
                    .dispatch(LogoutAction(userId: userId));
                setState(() {
                  errorMessageShown = false;
                });
              }
            },
            child: Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  'Logout',
                  style: GoogleFonts.lusitana(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ),
        ],
      ),
    );
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
    if (mounted && !isLoaded) {
      StoreProvider.of<AppState>(context)
          .dispatch(GetUserInfoAction(userId: userId));
      setState(() {
        errorMessageShown = false;
      });
    }

    if (appStore.state.userInfo.loadFailed && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.userInfo.error.message}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }

    if (appStore.state.authState.logoutFailed && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.authState.error.message}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }

    return Scaffold(
      body: StoreConnector<AppState, AppState>(
          onDidChange: ((previousState, state) {
            if (state.userInfo.loadFailed && !errorMessageShown) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    ToastMessageHandler.showErrorMessageSnackBar(
                        '${state.userInfo.error.message}'));
              });
              setState(() {
                errorMessageShown = true;
              });
            }

            if (state.authState.logoutFailed && !errorMessageShown) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    ToastMessageHandler.showErrorMessageSnackBar(
                        '${state.authState.error.message}'));
              });
              setState(() {
                errorMessageShown = true;
              });
            }
            if (mounted && state.authState.loggedOut) {
              SharedPreferences.getInstance().then((prefs) async {
                await prefs.remove('username');
                await prefs.remove('password');
                stopPeriodicTimer();
                StoreProvider.of<AppState>(context)
                    .dispatch(SetUserIdAction(userId: ''));
                StoreProvider.of<AppState>(context)
                    .dispatch(SetAccessCodeAction(accessCode: ''));
                Route newRoute = MaterialPageRoute(
                    builder: (context) => EnterLocalUserCredsScreen(
                          shouldAskForUsernameAndPassword: true,
                        ));
                Navigator.of(context).pushReplacement(newRoute);
                // prefs.clear().then((value) {
                //   if (value) {}
                // });
              });
            }
          }),
          converter: ((store) => store.state),
          builder: (context, state) => SingleChildScrollView(
                child: Container(
                    child: Column(children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Text(
                      'Hey ${username}, View your details here',
                      style: GoogleFonts.outfit(
                          fontSize: 40,
                          color: PaletteColors.blue2,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.fromLTRB(50, 20, 50, 20),
                      padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                      decoration: BoxDecoration(color: PaletteColors.blue3),
                      child: TextFormField(
                        decoration: InputDecoration(
                          suffix: ElevatedButton(
                            child: Icon(
                              Icons.save,
                              size: 10,
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.transparent),
                              fixedSize:
                                  MaterialStateProperty.all<Size>(Size(10, 10)),
                            ),
                            onPressed: () {
                              StoreProvider.of<AppState>(context).dispatch(
                                  SetTimedTickerPeriodAction(
                                      timedTickerPeriod:
                                          timedTickerPeriod as int));
                            },
                          ),
                          labelText: 'Timed Ticker Period',
                          labelStyle: GoogleFonts.outfit(
                            color: PaletteColors.blue2,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        controller: timedTickerPeriodController,
                        keyboardType: TextInputType.number,
                        onChanged: (newValue) {
                          if (mounted) {
                            setState(() {
                              timedTickerPeriod = int.parse(newValue);
                            });
                          }
                        },
                        onEditingComplete: () {},
                      )),
                  Container(
                      child: Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    padding: EdgeInsets.fromLTRB(0, 50, 0, 50),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50)),
                        gradient: LinearGradient(
                            colors: [PaletteColors.blue1, PaletteColors.blue2],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter)),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  width: screenSize.width * 0.4,
                                  height: screenSize.width * 0.3,
                                  decoration: BoxDecoration(
                                      color: PaletteColors.blue3,
                                      borderRadius: BorderRadius.circular(30)),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (state.userInfo.loaded)
                                          Text(
                                            '${state.userInfo.data!.noOfDynStocksOwned}',
                                            style: GoogleFonts.outfit(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: PaletteColors.blue2),
                                          ),
                                        if (state.userInfo.loaded)
                                          Text(
                                            'DynStocks',
                                            style: GoogleFonts.overlock(
                                                fontSize: 20,
                                                color: PaletteColors.blue2),
                                          ),
                                        if (state.userInfo.loading)
                                          (Text('Loading....')),
                                        if (state.userInfo.loadFailed)
                                          Text('Load Failed!')
                                      ]),
                                ),
                                Container(
                                  width: screenSize.width * 0.4,
                                  height: screenSize.width * 0.3,
                                  decoration: BoxDecoration(
                                      color: PaletteColors.purple2,
                                      borderRadius: BorderRadius.circular(30)),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (state.userInfo.loaded)
                                          Text(
                                            '${state.userInfo.data!.noOfTransactionsMade}',
                                            style: GoogleFonts.outfit(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: PaletteColors.blue2),
                                          ),
                                        if (state.userInfo.loaded)
                                          Text(
                                            'Transactions',
                                            style: GoogleFonts.overlock(
                                                fontSize: 20,
                                                color: PaletteColors.blue2),
                                          ),
                                        if (state.userInfo.loading)
                                          (Text('Loading....')),
                                        if (state.userInfo.loadFailed)
                                          Text('Load Failed!')
                                      ]),
                                )
                              ]),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  width: screenSize.width * 0.4,
                                  height: screenSize.width * 0.3,
                                  decoration: BoxDecoration(
                                      color: PaletteColors.purple2,
                                      borderRadius: BorderRadius.circular(30)),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (state.userInfo.loaded)
                                          Row(children: [
                                            Icon(
                                              Icons.currency_rupee,
                                              color: PaletteColors.blue2,
                                              size: 25,
                                            ),
                                            Text(
                                              '${state.userInfo.data!.netReturns.toStringAsFixed(2)}',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold,
                                                  color: PaletteColors.blue2),
                                            )
                                          ]),
                                        if (state.userInfo.loaded)
                                          Text(
                                            'Net returns from all DynStocks',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.overlock(
                                                fontSize: 15,
                                                color: PaletteColors.blue2),
                                          ),
                                        if (state.userInfo.loading)
                                          (Text('Loading....')),
                                        if (state.userInfo.loadFailed)
                                          Text('Load Failed!')
                                      ]),
                                ),
                                Container(
                                  width: screenSize.width * 0.4,
                                  height: screenSize.width * 0.3,
                                  decoration: BoxDecoration(
                                      color: PaletteColors.purple2,
                                      borderRadius: BorderRadius.circular(30)),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: []),
                                )
                              ]),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  child: ElevatedButton(
                                      style: ButtonStyle(
                                        padding: MaterialStateProperty.all(
                                            EdgeInsets.fromLTRB(
                                                15, 15, 15, 15)),
                                        shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        )),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.white),
                                      ),
                                      onPressed: () {
                                        showLogoutDialog();
                                      },
                                      child: Text(
                                        'Log Out',
                                        style: GoogleFonts.lusitana(
                                            color: PaletteColors.blue2,
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold),
                                      )))
                            ],
                          )
                        ]),
                  ))
                ])),
              )),
      bottomNavigationBar: BottomNavigationBarCustom(
        screenSize: screenSize,
        selectedIndex: 3,
      ),
    );
  }
}
