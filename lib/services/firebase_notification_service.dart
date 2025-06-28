import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

class FirebaseNotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final getIt = GetIt.instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Message notification channel
  static const AndroidNotificationChannel messageChannel =
      AndroidNotificationChannel(
          'high_importance_channel', 'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('notification'),
          playSound: true);

  // Calling notification channel
  static final AndroidNotificationChannel callingChannel =
      AndroidNotificationChannel(
    'calling_channel',
    'Incoming Calls',
    description: 'This channel is used for incoming call notifications.',
    importance: Importance.max,
    sound: const RawResourceAndroidNotificationSound('ring'),
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    try {
      await _firebaseMessaging.requestPermission();

      String? token = await _firebaseMessaging.getToken();
      getIt.registerSingleton<String>(token!, instanceName: "token");

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        // Create both channels
        await androidImplementation?.createNotificationChannel(messageChannel);
        await androidImplementation?.createNotificationChannel(callingChannel);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      print("ERROR in firebase initialize $e");
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    String? notificationType = message.data['type'];

    if (notificationType == 'call') {
      await _showCallingNotification(message);
    } else {
      await _showMessageNotification(message);
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    String? notificationType = message.data['type'];

    if (notificationType == 'call') {
      // Navigate to calling screen or handle call
      _handleIncomingCall(message);
    } else {
      // Navigate to chat screen
      _handleChatMessage(message);
    }
  }

  // Handle notification response (when user taps notification)
  void _onNotificationTapped(NotificationResponse response) {
    String? payload = response.payload;
    if (payload != null) {
      // Parse payload and handle accordingly
      print('Notification tapped with payload: $payload');
      // You can navigate to specific screens based on payload
    }
  }

  // Display message notification
  Future<void> _showMessageNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      String? sound;
      if (Platform.isAndroid) {
        sound = android?.sound ?? 'notification';
      } else if (Platform.isIOS) {
        sound = message.notification?.apple?.sound?.name ?? 'notification.mp3';
      }

      final androidDetails = AndroidNotificationDetails(
        messageChannel.id,
        messageChannel.name,
        channelDescription: messageChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(sound!.split('.').first),
        icon: android?.smallIcon,
      );

      final iosDetails = DarwinNotificationDetails(
        sound: sound,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: message.data['payload'],
      );
    }
  }

  // Display calling notification
  Future<void> _showCallingNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      String? sound;
      if (Platform.isAndroid) {
        sound = 'ring';
      } else if (Platform.isIOS) {
        sound = 'ring.mp3';
      }

      final androidDetails = AndroidNotificationDetails(
        callingChannel.id,
        callingChannel.name,
        channelDescription: callingChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(sound!),
        icon: '@drawable/ic_call', // You can create a custom call icon
        ongoing: true, // Makes notification persistent
        autoCancel: false, // Prevents auto dismiss
        fullScreenIntent: true, // Shows as full screen on lock screen
        category: AndroidNotificationCategory.call,
        actions: [
          AndroidNotificationAction(
            'accept_call',
            'Accept',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_call_accept'),
          ),
          AndroidNotificationAction(
            'decline_call',
            'Decline',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_call_decline'),
          ),
        ],
      );

      final iosDetails = DarwinNotificationDetails(
        sound: sound,
        categoryIdentifier: 'CALL_CATEGORY',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        999, // Use a fixed ID for calls so you can cancel it later
        notification.title ?? 'Incoming Call',
        notification.body ?? 'Someone is calling you',
        notificationDetails,
        payload: message.data['payload'],
      );
    }
  }

  // Handle incoming call
  void _handleIncomingCall(RemoteMessage message) {
    print('Handling incoming call');
    // Navigate to call screen
    // Get.to(() => CallScreen(callData: message.data));
  }

  // Handle chat message
  void _handleChatMessage(RemoteMessage message) {
    print('Handling chat message');
    // Navigate to chat screen
    // Get.to(() => ChatScreen(chatData: message.data));
  }

  // Cancel calling notification (call this when call is answered/declined)
  Future<void> cancelCallingNotification() async {
    await flutterLocalNotificationsPlugin.cancel(999);
  }
}

// import 'dart:io';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get_it/get_it.dart';

// class FirebaseNotificationService {
//   final _firebaseMessaging = FirebaseMessaging.instance;
//   final getIt = GetIt.instance;

//   // Instance of the plugin
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // Android channel (must match your FCM payload channelId if set)
//   static const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'high_importance_channel', // id
//       'High Importance Notifications', // title
//       description: 'This channel is used for important notifications.',
//       importance: Importance.max,
//       sound: RawResourceAndroidNotificationSound('notification'),
//       playSound: true // without extension
//       );

//   Future<void> initialize() async {
//     try {
//       // Request permissions
//       await _firebaseMessaging.requestPermission();

//       String? token = await _firebaseMessaging.getToken();
//       getIt.registerSingleton<String>(token!, instanceName: "token");

//       const AndroidInitializationSettings androidSettings =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//       const DarwinInitializationSettings iosSettings =
//           DarwinInitializationSettings();

//       await flutterLocalNotificationsPlugin.initialize(
//         const InitializationSettings(
//           android: androidSettings,
//           iOS: iosSettings,
//         ),
//       );

//       if (Platform.isAndroid) {
//         await flutterLocalNotificationsPlugin
//             .resolvePlatformSpecificImplementation<
//                 AndroidFlutterLocalNotificationsPlugin>()
//             ?.createNotificationChannel(channel);
//       }

//       // Handle foreground messages
//       // FirebaseMessaging.onMessage.listen(_showNotification);

//       // Handle background/terminated tap
//       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//         // Handle navigation or actions on notification tap
//       });
//     } catch (e) {
//       print("ERROR in firebase initialize $e");
//     }
//   }

//   // Display notification using flutter_local_notifications
//   Future<void> _showNotification(RemoteMessage message) async {
//     RemoteNotification? notification = message.notification;
//     AndroidNotification? android = message.notification?.android;

//     if (notification != null) {
//       String? sound;
//       if (Platform.isAndroid) {
//         sound =
//             android?.sound ?? 'notification'; // fallback to your custom sound
//       } else if (Platform.isIOS) {
//         sound = message.notification?.apple?.sound?.name ?? 'notification.mp3';
//       }

//       final androidDetails = AndroidNotificationDetails(
//         channel.id,
//         channel.name,
//         channelDescription: channel.description,
//         importance: Importance.max,
//         priority: Priority.high,
//         sound: RawResourceAndroidNotificationSound(sound!.split('.').first),
//         icon: android?.smallIcon,
//       );

//       final iosDetails = DarwinNotificationDetails(
//         sound: sound,
//       );

//       final notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );

//       await flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         notificationDetails,
//         payload: message.data['payload'],
//       );
//     }
//   }
// }
