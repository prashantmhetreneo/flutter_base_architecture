import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';

extension BaseWidgetExtension on Widget {
  void toastMessage(String message,
      {Toast toastLength,
      ToastGravity gravity,
      Color backgroundColor = Colors.black,
      int timeInSecForIosWeb,
      Color textColor: Colors.white,
      double fontSize = 14}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: toastLength,
        gravity: gravity,
        timeInSecForIosWeb: timeInSecForIosWeb,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize);
  }
}
