import 'package:chatapp/providers/connectivity_provider.dart';
import 'package:chatapp/providers/counter_provider.dart';
import 'package:chatapp/providers/last_message_provider.dart';
import 'package:chatapp/providers/message_provider.dart';
import 'package:chatapp/services/sharedpreferences_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class GetitService {
  static Future<Map<String, dynamic>> getItSetter(BuildContext context) async {
    final getIt = GetIt.instance;

    var uuid = await SharedpreferencesStorage.getJustOne("uuid");
    var mobileNumber = await SharedpreferencesStorage.getJustOne("mobile");

    if (!getIt.isRegistered<String>(instanceName: "uuid")) {
      getIt.registerSingleton<String>(uuid, instanceName: "uuid");
    }
    if (!getIt.isRegistered<String>(instanceName: "mobile")) {
      getIt.registerSingleton<String>(mobileNumber, instanceName: "mobile");
    }
    if (getIt.isRegistered<String>(instanceName: "location")) {
      getIt.unregister<String>(instanceName: "location");
      getIt.registerSingleton<String>("main", instanceName: "location");
    } else {
      getIt.registerSingleton<String>("main", instanceName: "location");
    }
    // Ensure ConnectivityProvider is registered
    if (!getIt.isRegistered<ConnectivityProvider>()) {
      final cProvider =
          Provider.of<ConnectivityProvider>(context, listen: false);
      getIt.registerSingleton<ConnectivityProvider>(cProvider);
    }
    final lastMessageProvider =
        Provider.of<LastMessageProvider>(context, listen: false);
    if (!getIt.isRegistered<LastMessageProvider>()) {
      getIt.registerSingleton<LastMessageProvider>(lastMessageProvider);
    }
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    if (!getIt.isRegistered<MessageProvider>()) {
      getIt.registerSingleton<MessageProvider>(messageProvider);
    }
    final counterProvider =
        Provider.of<CounterProvider>(context, listen: false);
    if (!getIt.isRegistered<CounterProvider>()) {
      getIt.registerSingleton<CounterProvider>(counterProvider);
    }
    return {
      "messageProvider": messageProvider,
      "lastMessageProvider": lastMessageProvider,
      "counterProvider": counterProvider
    };
  }
}
