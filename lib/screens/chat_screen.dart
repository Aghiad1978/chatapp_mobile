import 'package:chatapp/models/friend.dart';
import 'package:chatapp/providers/connectivity_provider.dart';
import 'package:chatapp/providers/message_provider.dart';
import 'package:chatapp/logic/socket_logic.dart';
import 'package:chatapp/screens/audio_record_screen.dart';
import 'package:chatapp/screens/camera_screen.dart';
import 'package:chatapp/widgets/message_received.dart';
import 'package:chatapp/widgets/message_sent.dart';
import 'package:chatapp/widgets/styled_chatscreen_appbar.dart';
import 'package:chatapp/widgets/styled_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.friend,
  });
  final Friend friend;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late IO.Socket _socket;
  late Friend friend;
  late String uuid;
  late ConnectivityProvider connectivityProvider;
  late MessageProvider messageProvider;
  final ScrollController _scrollController = ScrollController();
  final getIt = GetIt.instance;
  int offset = 0;

  TextEditingController controller = TextEditingController();
  void prepareGetIT() {
    if (getIt.isRegistered<Friend>(instanceName: "currentFriend")) {
      getIt.unregister<Friend>(instanceName: "currentFriend");
    }

    getIt.unregister<String>(instanceName: "location");
    uuid = getIt<String>(instanceName: "uuid");
    getIt.registerSingleton<String>("chat", instanceName: "location");
    getIt.registerSingleton<Friend>(friend, instanceName: "currentFriend");
  }

  @override
  void initState() {
    friend = widget.friend;
    _scrollController.addListener(_onScroll);
    prepareGetIT();
    messageProvider = getIt<MessageProvider>();
    SocketLogic.setFriendUuid(widget.friend.uuid);
    SocketLogic.setMessageProvider(messageProvider);
    _socket = getIt<IO.Socket>();
    _socket.emit("status", widget.friend.uuid);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await messageProvider.getMessagesFromInternalDB(25, offset);
      await messageProvider.checkMessagesStatusWithServer();
    });
    super.initState();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 10) {
      print('Reached the head of the list!');
      // offset += 5;
      // messageProvider.getMessagesFromInternalDB(15, offset);
    }
  }

  @override
  void dispose() {
    SocketLogic.friendUuid = null;
    messageProvider.clearMessages();
    getIt.unregister<String>(instanceName: "location");
    getIt.registerSingleton<String>("main", instanceName: "location");
    messageProvider.clearMessages();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Friend friend = widget.friend;

    return Scaffold(
      appBar: StyledChatscreenAppbar(
        uuid: uuid,
        friend: friend,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Consumer<MessageProvider>(
                  builder: (context, provider, child) {
                    final messages = provider.messages;
                    if (messageProvider.shouldscrolltoBottom == true) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                        messageProvider.shouldscrolltoBottom = false;
                      });
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        if (index < 0 || index >= messages.length) {
                          return const SizedBox.shrink();
                        }
                        return messages[index].senderUuid == uuid
                            ? MessageSent(message: messages[index])
                            : MessageReceived(
                                message: messages[index],
                                friendName: friend.friendName,
                              );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: StyledTextfield(
                        controller: controller,
                        title: "message",
                        textInput: TextInputType.text,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        messageProvider.sendMessage(controller.text, "text");
                        controller.text = "";
                        FocusScope.of(context).unfocus();
                      },
                      icon: Icon(
                        Icons.send,
                        color: const Color.fromARGB(255, 49, 136, 52),
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraScreen(),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(15)),
                        backgroundColor: WidgetStateProperty.all(
                          const Color.fromARGB(255, 216, 215, 215),
                        ),
                        shape: WidgetStateProperty.all(CircleBorder()),
                      ),
                      icon: Icon(Icons.camera_alt, color: Colors.pink),
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return AudioRecordScreen();
                          },
                        );
                      },
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(15)),
                        backgroundColor: WidgetStateProperty.all(
                          const Color.fromARGB(255, 216, 215, 215),
                        ),
                        shape: WidgetStateProperty.all(CircleBorder()),
                      ),
                      icon: Icon(Icons.mic, color: Colors.blue, size: 30),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.215,
            right: MediaQuery.of(context).size.width - 60,
            child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
                onPressed: () {
                  _scrollToBottom();
                },
                child: Icon(
                  Icons.download_sharp,
                  size: 20,
                  color: Colors.green,
                )),
          )
        ],
      ),
    );
  }
}
