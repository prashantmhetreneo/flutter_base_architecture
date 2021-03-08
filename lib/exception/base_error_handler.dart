import 'package:flutter/widgets.dart';

import 'base_error.dart';
import 'base_error_parser.dart';

class ErrorHandler<T extends BaseErrorParser> {
  final T parser;

  ErrorHandler(this.parser);

  String parseErrorType(BuildContext context, BaseError error) {
    return parser.parseError(context, error);
  }
}
