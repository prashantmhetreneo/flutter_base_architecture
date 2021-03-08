import 'dart:convert';

import 'package:flutter_base_architecture/constants/session_manager_const.dart';
import 'package:flutter_base_architecture/dto/base_dto.dart';
import 'package:flutter_base_architecture/utils/session_manager.dart';

abstract class UserStore<T extends BaseDto> {
  Future<bool> setUser(T userDto) async {
    var preference = await SessionManager.getInstance();
    return preference.setString(const_user, json.encode(userDto.toJson()));
  }

  Future<bool> userIsLoggedIn() async {
    var preference = await SessionManager.getInstance();
    return ((preference.getString(const_user) != null) ? true : false);
  }

  Future<T> getLoggedInUserJson() async {
    var preference = await SessionManager.getInstance();
    return preference.getString(const_user) != null
        ? mapUserDto(json.decode(preference.getString(const_user)))
        : null;
  }

  Future<bool> removeUser() async {
    var preference = await SessionManager.getInstance();
    return preference.remove(const_user);
  }

  T mapUserDto(decode);
}
