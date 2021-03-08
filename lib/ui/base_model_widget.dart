import 'package:flutter/material.dart';
import 'package:flutter_base_architecture/exception/base_error.dart';
import 'package:flutter_base_architecture/exception/base_error_handler.dart';
import 'package:flutter_base_architecture/exception/base_error_parser.dart';
import 'package:flutter_base_architecture/extensions/widget_extensions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
abstract class BaseModelWidget<T, ErrorParser extends BaseErrorParser>
    extends Widget {
  ErrorHandler<ErrorParser> _errorHandler;

  @protected
  Widget build(BuildContext context, T model);

  @override
  DataProviderElement<T, ErrorParser> createElement() =>
      DataProviderElement<T, ErrorParser>(this);

  void showToastMessage(String message,
      {Toast toastLength,
      ToastGravity gravity,
      Color backgroundColor,
      int timeInSecForIosWeb,
      Color textColor,
      double fontSize}) {
    toastMessage(message,
        toastLength: toastLength,
        gravity: gravity,
        timeInSecForIosWeb: timeInSecForIosWeb,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize);
  }

  String getErrorMessage(BuildContext context, BaseError error) {
    return _errorHandler.parseErrorType(context, error);
  }
}

class DataProviderElement<T, ErrorParser extends BaseErrorParser>
    extends ComponentElement {
  DataProviderElement(BaseModelWidget widget) : super(widget);

  @override
  BaseModelWidget get widget => super.widget;

  @override
  Widget build() {
    widget._errorHandler =
        Provider.of<ErrorHandler<ErrorParser>>(this, listen: false);
    return widget.build(this, Provider.of<T>(this));
  }

  @override
  void update(BaseModelWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild();
  }
}
