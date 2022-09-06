import 'dart:async';

import 'package:dynstocks/main.dart';
import 'package:dynstocks/models/authentication.dart';
import 'package:dynstocks/models/bar_chart.dart';
import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/models/local_user_creds.dart';
import 'package:dynstocks/redux/actions/authentication.actions.dart';
import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/actions/kotak_stock_api.actions.dart';
import 'package:dynstocks/redux/actions/local_user_creds.actions.dart';
import 'package:dynstocks/redux/actions/ticker_data.actions.dart';
import 'package:dynstocks/redux/actions/transactions.actions.dart';
import 'package:dynstocks/redux/app_state.dart';
import 'package:dynstocks/services/transactions.service.dart';
import 'package:dynstocks/static/toast_message_handler.dart';
import 'package:dynstocks/static/timed_ticker_call.dart';
import 'package:dynstocks/views/screens/events_today_screen.dart';
import 'package:dynstocks/views/widgets/bottom_navigation_bar_custom.dart';
import 'package:dynstocks/views/widgets/transactions_today_bar_chart.dart';
import 'package:dynstocks/views/widgets/transactions_today_details.dart';
import 'package:dynstocks/views/screens/view_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import '../../models/transactions.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../../models/colors.dart';

class EnterLocalUserCredsScreen extends StatefulWidget {
  bool shouldAskForUsernameAndPassword = false;
  EnterLocalUserCredsScreen(
      {Key? key, required this.shouldAskForUsernameAndPassword})
      : super(key: key);

  // This widget is the root of your application.
  @override
  // ignore: library_private_types_in_public_api
  _EnterLocalUserCredsScreenState createState() =>
      _EnterLocalUserCredsScreenState(
          shouldAskForUsernameAndPassword: shouldAskForUsernameAndPassword);
}

class _EnterLocalUserCredsScreenState extends State<EnterLocalUserCredsScreen>
    with RouteAware {
  String accessCode = '';
  String username = '';
  String password = '';
  bool shouldAskForUsernameAndPassword = false;
  bool userNameAndPasswordObtained = false;
  bool errorMessageShown = true;
  _EnterLocalUserCredsScreenState(
      {required this.shouldAskForUsernameAndPassword});
  TextEditingController accessCodeController = TextEditingController();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    super.initState();
    accessCode = '';
    username = '';
    password = '';
    userNameAndPasswordObtained = !shouldAskForUsernameAndPassword;
    if (!shouldAskForUsernameAndPassword) {
      SharedPreferences.getInstance().then((prefs) {
        if (mounted) {
          String? userId = prefs.getString('userId');
          StoreProvider.of<AppState>(context)
              .dispatch(SetUserIdAction(userId: userId as String));
        }
      });
    }
    accessCodeController = TextEditingController(
      text: accessCode,
    );
    accessCodeController.selection =
        TextSelection.collapsed(offset: accessCodeController.text.length);
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        int? timedTickerPeriod = prefs.getInt('timedTickerPeriod');
        timedTickerPeriod ??= 10;
        StoreProvider.of<AppState>(context).dispatch(SetTimedTickerPeriodAction(
            timedTickerPeriod: timedTickerPeriod as int));
      }
    });
  }

  // Stops the periodic timer, possibly invoked when the screen goes out of focus
  void stopPeriodicTimer() {
    TimedTickerCall.stopTimedTickerCallForDynStocks();
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
    stopPeriodicTimer();
    if ((appStore.state.kotakStockAPI.loginFailed) && !errorMessageShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastMessageHandler.showErrorMessageSnackBar(
                '${appStore.state.kotakStockAPI.error}'));
      });
      setState(() {
        errorMessageShown = true;
      });
    }
    if ((appStore.state.authState.loginFailed) && !errorMessageShown) {
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
            onDidChange: (previousState, state) {
              if ((state.kotakStockAPI.loginFailed) && !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.kotakStockAPI.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
              if ((state.authState.loginFailed) && !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.authState.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }
              if (mounted &&
                  state.kotakStockAPI.jwtToken.isNotEmpty &&
                  state.kotakStockAPI.loggedIn &&
                  !state.kotakStockAPI.loggingIn &&
                  state.userId.isNotEmpty) {
                Future.delayed(Duration(seconds: 1), () {
                  if (mounted) {
                    StoreProvider.of<AppState>(context)
                        .dispatch(SetUserIdAction(userId: state.userId));
                    StoreProvider.of<AppState>(context)
                        .dispatch(SetAccessCodeAction(accessCode: accessCode));
                    SharedPreferences.getInstance().then((prefs) {
                      DateTime now = DateTime.now();
                      prefs.setString(
                          'accessCode ${now.day}/${now.month}/${now.year}',
                          accessCode);
                      prefs.setString(
                          'KOTAK jwtToken', state.kotakStockAPI.jwtToken);
                      Route newRoute = MaterialPageRoute(
                          builder: (context) => EventsTodayScreen());
                      Navigator.of(context).pushReplacement(newRoute);
                    });
                  }
                });
              } else if (mounted &&
                  state.kotakStockAPI.loginFailed &&
                  !errorMessageShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      ToastMessageHandler.showErrorMessageSnackBar(
                          '${state.kotakStockAPI.error}'));
                });
                setState(() {
                  errorMessageShown = true;
                });
              }

              if (mounted &&
                  state.authState.loggedIn &&
                  !userNameAndPasswordObtained) {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('userId', state.authState.data!.userId);
                  prefs.setString('username', username);
                  StoreProvider.of<AppState>(context).dispatch(SetUserIdAction(
                      userId: state.authState.data!.userId as String));
                  Future.delayed(Duration(seconds: 1), () {
                    setState(() {
                      accessCode = '';
                      userNameAndPasswordObtained = true;
                    });
                  });
                });
              }
            },
            converter: ((store) => store.state),
            builder: (context, state) {
              if (userNameAndPasswordObtained == true) {
                return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Text(
                          'Enter Access Code',
                          style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: PaletteColors.blue2),
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.fromLTRB(50, 20, 50, 20),
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                          decoration: BoxDecoration(color: PaletteColors.blue3),
                          child: TextFormField(
                            controller: accessCodeController,
                            keyboardType: TextInputType.number,
                            onChanged: (newValue) {
                              if (mounted) {
                                setState(() {
                                  accessCode = newValue;
                                });
                              }
                            },
                          )),
                      Container(
                          child: ElevatedButton(
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                    EdgeInsets.fromLTRB(15, 15, 15, 15)),
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                )),
                                backgroundColor: MaterialStateProperty.all(
                                    PaletteColors.blue2),
                              ),
                              onPressed: () {
                                if (mounted) {
                                  StoreProvider.of<AppState>(context).dispatch(
                                      KotakStockAPILoginAction(
                                          accessCode: accessCode));
                                  setState(() {
                                    errorMessageShown = false;
                                  });
                                }
                              },
                              child: Text(
                                'Submit',
                                style: GoogleFonts.lusitana(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold),
                              )))
                    ]);
              } else {
                return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Text(
                          'Enter Username',
                          style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: PaletteColors.blue2),
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.fromLTRB(50, 20, 50, 20),
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                          decoration: BoxDecoration(color: PaletteColors.blue3),
                          child: TextFormField(
                            initialValue: username,
                            onChanged: (newValue) {
                              if (mounted) {
                                setState(() {
                                  username = newValue;
                                });
                              }
                            },
                          )),
                      Container(
                        child: Text(
                          'Enter Password',
                          style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: PaletteColors.blue2),
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.fromLTRB(50, 20, 50, 20),
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                          decoration: BoxDecoration(color: PaletteColors.blue3),
                          child: TextFormField(
                            initialValue: password,
                            obscureText: true,
                            onChanged: (newValue) {
                              if (mounted) {
                                setState(() {
                                  password = newValue;
                                });
                              }
                            },
                          )),
                      Container(
                          child: ElevatedButton(
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                    EdgeInsets.fromLTRB(15, 15, 15, 15)),
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                )),
                                backgroundColor: MaterialStateProperty.all(
                                    PaletteColors.blue2),
                              ),
                              onPressed: () {
                                if (mounted) {
                                  StoreProvider.of<AppState>(context).dispatch(
                                      LoginAction(
                                          authBody: AuthBody(
                                              username: username,
                                              password: password)));
                                  setState(() {
                                    errorMessageShown = false;
                                  });
                                }
                              },
                              child: Icon(
                                Icons.arrow_forward,
                                size: 30,
                                color: Colors.white,
                              )))
                    ]);
              }
            }));
  }
}
