import 'package:flutter/widgets.dart';

import 'base_error.dart';

abstract class BaseErrorParser {
  BaseErrorParser();

  @mustCallSuper
  String parseError(BuildContext context, BaseError error) {
    String result;
    switch (error.type) {
      case BaseErrorType.DEFAULT:
        result = "Something went wrong. Please try again.";
    }
    return result;
  }
}
