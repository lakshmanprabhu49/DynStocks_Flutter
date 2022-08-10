import 'package:dynstocks/models/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToastMessageHandler {
  static SnackBar showErrorMessageSnackBar(String text) {
    return SnackBar(
        elevation: 1.0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
        backgroundColor: AccentColors.red2,
        content: Container(
          color: AccentColors.red2,
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 20,
              color: AccentColors.red1,
            ),
          ),
        ));
  }

  static SnackBar showInfoMessageSnackBar(String text) {
    return SnackBar(
        elevation: 1.0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
        backgroundColor: AccentColors.blue2,
        content: Container(
          color: AccentColors.blue2,
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 20,
              color: AccentColors.blue1,
            ),
          ),
        ));
  }

  static SnackBar showSuccessMessageSnackBar(String text) {
    return SnackBar(
        elevation: 1.0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
        backgroundColor: AccentColors.green2,
        content: Container(
          color: AccentColors.green2,
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 20,
              color: AccentColors.green1,
            ),
          ),
        ));
  }
}
