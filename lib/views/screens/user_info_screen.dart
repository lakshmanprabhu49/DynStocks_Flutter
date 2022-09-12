import 'dart:async';
import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/dyn_stocks.dart';
import 'package:dynstocks/redux/actions/authentication.actions.dart';
import 'package:dynstocks/redux/actions/local_user_creds.actions.dart';
import 'package:dynstocks/redux/actions/user_info.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/gmail_error_message.service.dart';
import 'package:dynstocks/static/post-market-timer.dart';
import 'package:dynstocks/static/toast_message_handler.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/screens/enter_local_user_creds_screen.dart';
import 'package:dynstocks/views/widgets/bottom_navigation_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

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

  Future<String?> showDeleteUserDialog() {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Delete',
          style: GoogleFonts.outfit(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AccentColors.red1,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this user?',
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
                StoreProvider.of<AppState>(context)
                    .dispatch(DeleteUserAction(userId: userId));
                setState(() {
                  errorMessageShown = false;
                });
              }
            },
            child: Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  'Delete',
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

  Future<String?> showCannotDeleteUserDialog() {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Cannot Delete User',
          style: GoogleFonts.outfit(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AccentColors.red1,
          ),
        ),
        content: Text(
          'The user already has some undeleted dynstocks. Please delete them first.',
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
            onPressed: () => Navigator.pop(context, 'OK'),
            child: Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  'OK',
                  style: GoogleFonts.lusitana(
                    fontSize: 15,
                    color: AccentColors.red1,
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
        GmailErrorMessageService().signIntoGoogle();
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

    if (appStore.state.userInfo.loadFailed && !errorMessageShown && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.userInfo.error}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }

    if (appStore.state.authState.logoutFailed &&
        !errorMessageShown &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.authState.error}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }

    return Scaffold(
      body: StoreConnector<AppState, AppState>(
          onDidChange: ((previousState, state) {
            if (state.userInfo.loadFailed && !errorMessageShown && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    ToastMessageHandler.showErrorMessageSnackBar(
                        '${state.userInfo.error}'));
              });
              setState(() {
                errorMessageShown = true;
              });
            }

            if (state.authState.logoutFailed && !errorMessageShown && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    ToastMessageHandler.showErrorMessageSnackBar(
                        '${state.authState.error}'));
              });
              setState(() {
                errorMessageShown = true;
              });
            }

            if (state.userInfo.deleteFailed && !errorMessageShown && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    ToastMessageHandler.showErrorMessageSnackBar(
                        '${state.userInfo.error}'));
              });
              setState(() {
                errorMessageShown = true;
              });
            }

            if (state.userInfo.deleted) {
              StoreProvider.of<AppState>(context)
                  .dispatch(LogoutAction(userId: userId));
              setState(() {
                errorMessageShown = false;
              });
            }

            if (mounted && state.authState.loggedOut) {
              SharedPreferences.getInstance().then((prefs) async {
                prefs.clear().then((value) {
                  if (value) {
                    stopPeriodicTimer();
                    StoreProvider.of<AppState>(context)
                        .dispatch(SetUserIdAction(userId: ''));
                    StoreProvider.of<AppState>(context)
                        .dispatch(SetUsernameAction(username: ''));
                    StoreProvider.of<AppState>(context)
                        .dispatch(SetAccessCodeAction(accessCode: ''));
                    Route newRoute = MaterialPageRoute(
                        builder: (context) => EnterLocalUserCredsScreen(
                              shouldAskForUsernameAndPassword: true,
                            ));
                    Navigator.of(context).pushReplacement(newRoute);
                  }
                });
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
                                        if (state.userInfo.loaded &&
                                            !(state.userInfo.deleted))
                                          SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Text(
                                                '${state.userInfo.data!.noOfDynStocksOwned}',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.bold,
                                                    color: PaletteColors.blue2),
                                              )),
                                        if (state.userInfo.loaded &&
                                            !(state.userInfo.deleted))
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
                                        if (state.userInfo.loaded &&
                                            !(state.userInfo.deleted))
                                          SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Text(
                                                '${state.userInfo.data!.noOfTransactionsMade}',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.bold,
                                                    color: PaletteColors.blue2),
                                              )),
                                        if (state.userInfo.loaded &&
                                            !(state.userInfo.deleted))
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
                                  margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
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
                                        if (state.userInfo.loaded &&
                                            !(state.userInfo.deleted))
                                          SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(children: [
                                                Icon(
                                                  Icons.currency_rupee,
                                                  color: PaletteColors.blue2,
                                                  size: 25,
                                                ),
                                                Text(
                                                  '${state.userInfo.data!.netReturns.toStringAsFixed(2)}',
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          PaletteColors.blue2),
                                                )
                                              ])),
                                        if (state.userInfo.loaded &&
                                            !(state.userInfo.deleted))
                                          Text(
                                            'Net returns from all DynStocks',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.overlock(
                                                fontSize: 15,
                                                color: PaletteColors.blue2),
                                          ),
                                        if (state.userInfo.loading &&
                                            !(state.userInfo.deleted))
                                          (Text('Loading....')),
                                        if (state.userInfo.loadFailed)
                                          Text('Load Failed!')
                                      ]),
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                                  width: screenSize.width * 0.4,
                                  height: screenSize.width * 0.3,
                                  decoration: BoxDecoration(
                                      color: PaletteColors.blue3,
                                      borderRadius: BorderRadius.circular(30)),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: []),
                                )
                              ]),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                      ))),
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
                                                AccentColors.red1),
                                      ),
                                      onPressed: () {
                                        if (state
                                            .allDynStocks.data.isNotEmpty) {
                                          showCannotDeleteUserDialog();
                                        } else {
                                          showDeleteUserDialog();
                                        }
                                      },
                                      child: Text(
                                        'Delete User',
                                        style: GoogleFonts.lusitana(
                                            color: PaletteColors.blue3,
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
