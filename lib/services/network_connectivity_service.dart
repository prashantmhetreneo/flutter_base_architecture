import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_base_architecture/constants/connectivity_status.dart';

class NetworkConnectivityService {
  // Create our public controller
  StreamController<ConnectivityStatus> connectionStatusController =
      StreamController<ConnectivityStatus>();

  NetworkConnectivityService() {
    _initConnectivity();
    // Subscribe to the connectivity Chanaged Steam
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // Use Connectivity() here to gather more info if you need t
      connectionStatusController.add(_getStatusFromResult(result));
    });
  }

  void _initConnectivity() async {
    ConnectivityResult result = ConnectivityResult.none;
    try {
      result = await Connectivity().checkConnectivity();
    } on PlatformException catch (e) {
      print("CONNECTIVITY PLATFORM EXCEPTION::: ${e.toString()}");
    }
    return connectionStatusController.add(_getStatusFromResult(result));
  }

  // Convert from the third part enum to our own enum
  ConnectivityStatus _getStatusFromResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.mobile:
        return ConnectivityStatus.Cellular;
      case ConnectivityResult.wifi:
        return ConnectivityStatus.WiFi;
      case ConnectivityResult.none:
        return ConnectivityStatus.Offline;
      default:
        return ConnectivityStatus.Offline;
    }
  }
}
