import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/models/last_message.dart';
import 'package:chatapp/providers/connectivity_provider.dart';
import 'package:chatapp/providers/counter_provider.dart';
import 'package:chatapp/providers/last_message_provider.dart';
import 'package:chatapp/providers/message_provider.dart';
import 'package:chatapp/services/getit_service_for_mainscreen.dart';
import 'package:chatapp/logic/socket_logic.dart';
import 'package:chatapp/widgets/developer_popupmenu.dart';
import 'package:chatapp/widgets/list_tile_last_message.dart';
import 'package:chatapp/widgets/settings_popupmenu.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String userName;
  late IO.Socket socket;
  bool _isInit = false;
  late SocketLogic socketLogic;
  late ConnectivityProvider connectivityProvider;
  late MessageProvider messageProvider;
  late LastMessageProvider lastMessageProvider;
  late CounterProvider counterProvider;
  final getIt = GetIt.instance;

  void socketLoader() {
    try {
      socketLogic = SocketLogic();
      socket = socketLogic.socket;
      getIt.registerSingleton<SocketLogic>(socketLogic);
      getIt.registerSingleton<IO.Socket>(socket);
    } catch (e) {
      print("Error connecting to socket");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      connectivityProvider = Provider.of<ConnectivityProvider>(context);
      _isInit = true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final getItMap = await GetitService.getItSetter(context);
      messageProvider = getItMap["messageProvider"];
      lastMessageProvider = getItMap["lastMessageProvider"];
      counterProvider = getItMap["counterProvider"];
      SocketLogic.setMessageProvider(messageProvider);
      SocketLogic.setLMessageProvider(lastMessageProvider);
      SocketLogic.setCounterProvider(counterProvider);
      socketLoader();
      await lastMessageProvider.getLastMessagesFromInternalDB();
      await lastMessageProvider.getFriendsListFromInternalDb();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Crypto Chat",
          style: TextStyle(color: AppColors.writtingColor),
        ),
        backgroundColor: AppColors.appBarColor,
        actions: [
          connectivityProvider.isOnLine
              ? Icon(
                  Icons.wifi,
                  color: Colors.green,
                )
              : Icon(
                  Icons.wifi_off,
                  color: Colors.red,
                ),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).pushNamed("/search");
            },
            icon: Icon(Icons.search, color: Colors.green),
          ),
          SettingsPopupmenu(),
          DeveloperPopupmenu(),
        ],
      ),
      body: Column(children: [
        Expanded(child: Consumer<LastMessageProvider>(
          builder: (context, provider, child) {
            final friends = provider.friends;
            final lMessages = provider.lMessages;
            if (friends.isEmpty) {
              return Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No conversations yet',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed("/search");
                      },
                      child: Text("Start Messaging"))
                ],
              ));
            }

            return ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                lMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                LastMessage lastMsg = lMessages[index];
                Friend friend = friends.firstWhere((f) =>
                    lastMsg.senderUuid == f.uuid ||
                    lastMsg.receiverUuid == f.uuid);
                return LastMessageTile(
                  friend: friend,
                  lastMessage: lastMsg,
                );
              },
            );
          },
        )),
      ]),
    );
  }
}
