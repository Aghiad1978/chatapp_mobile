import 'package:chatapp/models/message_table.dart';
import 'package:flutter/material.dart';

class CounterProvider extends ChangeNotifier {
  CounterProvider();
  final Map<String, int> _counters = {};

  int counterFor(String friendUuid) => _counters[friendUuid] ?? 0;

  Future<void> setInitialCounter(String friendUuid) async {
    _counters[friendUuid] =
        await MessageTable.getUnReadMessagesNumbers(friendUuid);
    notifyListeners();
  }

  void incrementCounter(String friendUuid) {
    _counters[friendUuid] = (_counters[friendUuid] ?? 0) + 1;
    notifyListeners();
  }

  void clearCounter(String friendUuid) {
    _counters[friendUuid] = 0;
    notifyListeners();
  }
}
