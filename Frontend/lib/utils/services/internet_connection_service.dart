import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:notes_app/main.dart';
import 'package:notes_app/utils/res/snackbar.dart';

/// Adding a listener to check the internet status
/// Show snackbar dialog msg, when internet is connected or disconnected
Future<void> internetStatusListener(BuildContext context) async {
  Timer listenerTimerDebounce = Timer(Duration(), () {});
  var instance = InternetConnectionChecker.createInstance();
  isInternetConnected =
      await instance.connectionStatus == InternetConnectionStatus.connected;

  instance.onStatusChange.listen((status) {
    listenerTimerDebounce.cancel();
    if (status == InternetConnectionStatus.connected) {
      listenerTimerDebounce = Timer(Duration(seconds: 10), () {
        isInternetConnected = true;
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(successSnackBar("Internet connected"));
        }
      });
    } else if (status == InternetConnectionStatus.disconnected) {
      listenerTimerDebounce = Timer(Duration(seconds: 1), () {
        isInternetConnected = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(failedSnackBar("Internet disconnected"));
        }
      });
    }
  });
}
