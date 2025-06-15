import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnLine = false;
  bool get isOnLine => _isOnLine;

  void setOnline(bool status) {
    _isOnLine = status;
    notifyListeners();
  }
}
