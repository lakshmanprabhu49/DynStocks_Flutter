import 'package:dynstocks/models/colors.dart';
import 'package:dynstocks/views/screens/create_dynstock_screen.dart';
import 'package:dynstocks/views/screens/events_today_screen.dart';
import 'package:dynstocks/views/screens/user_info_screen.dart';
import 'package:dynstocks/views/screens/view_dynstocks_list_screen.dart';
import 'package:flutter/material.dart';

class BottomNavigationBarCustom extends StatelessWidget {
  Size screenSize;
  int selectedIndex;
  BottomNavigationBarCustom({
    required this.screenSize,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        child: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10,
      unselectedFontSize: 9,
      backgroundColor: PaletteColors.blue2,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: Icon(
              Icons.stacked_line_chart_rounded,
              size: 20,
            ),
            label: 'Transaction Today'),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.stacked_bar_chart,
              size: 20,
            ),
            label: 'View DynStocks'),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.add_shopping_cart_outlined,
              size: 20,
            ),
            label: 'Create DynStock'),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.supervised_user_circle,
              size: 20,
            ),
            label: 'User Info'),
      ],
      currentIndex: selectedIndex,
      selectedIconTheme: IconThemeData(color: PaletteColors.blue3),
      onTap: (currentIndex) {
        if (currentIndex != selectedIndex) {
          Route newRoute =
              MaterialPageRoute(builder: (context) => EventsTodayScreen());
          switch (currentIndex) {
            case 0:
              newRoute =
                  MaterialPageRoute(builder: (context) => EventsTodayScreen());
              break;
            case 1:
              newRoute = MaterialPageRoute(
                  builder: (context) => ViewDynStocksListScreen());
              break;
            case 2:
              newRoute = MaterialPageRoute(
                  builder: (context) => CreateDynStockScreen());
              break;
            case 3:
              newRoute =
                  MaterialPageRoute(builder: (context) => UserInfoScreen());
              break;
          }
          Navigator.pushReplacement(context, newRoute);
        }
      },
    ));
  }
}
