import 'package:camera/camera.dart';
import 'package:chatapp/Theme/theme1.dart';
import 'package:chatapp/providers/connectivity_provider.dart';
import 'package:chatapp/providers/counter_provider.dart';
import 'package:chatapp/providers/last_message_provider.dart';
import 'package:chatapp/providers/message_provider.dart';
import 'package:chatapp/screens/chat_screen.dart';
import 'package:chatapp/screens/main_screen.dart';
import 'package:chatapp/screens/register_screen.dart';
import 'package:chatapp/screens/search_screen.dart';
import 'package:chatapp/screens/start_screen.dart';
import 'package:chatapp/services/firebase_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

GetIt getIt = GetIt.instance;
Future<void> prepare() async {
  getIt.registerSingleton<List<CameraDescription>>(await availableCameras());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  // You can handle background messages here if needed
  String? notificationType = message.data['type'];
  if (notificationType == 'call') {
    print('Background call notification received');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseNotificationService().initialize();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await flutterLocalNotificationsPlugin.cancelAll();

  await prepare();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => LastMessageProvider()),
        ChangeNotifierProvider(create: (_) => CounterProvider()),
      ],
      child: CryptoMain(),
    ),
  );
}

class CryptoMain extends StatelessWidget {
  const CryptoMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: "/",
      onGenerateRoute: (settings) {
        if (settings.name == "/chat") {
          final Map<String, dynamic> argsMap =
              settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(friend: argsMap["friend"]),
          );
        }
        return null;
      },
      routes: {
        "/": (context) => StartScreen(),
        "/main": (context) => MainScreen(),
        "/search": (context) => SearchScreen(),
        "/register": (context) => RegisterScreen(),
      },
      theme: theme1,
    );
  }
}
