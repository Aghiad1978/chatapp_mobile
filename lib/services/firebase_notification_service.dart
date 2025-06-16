import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

class FirebaseNotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final getIt = GetIt.instance;

  // Instance of the plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android channel (must match your FCM payload channelId if set)
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification1'),
      playSound: true // without extension
      );

  Future<void> initialize() async {
    try {
      // Request permissions
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
      );

      if (Platform.isAndroid) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Handle foreground messages
      // FirebaseMessaging.onMessage.listen(_showNotification);

      // Handle background/terminated tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Handle navigation or actions on notification tap
      });
    } catch (e) {
      print("ERROR in firebase initialize $e");
    }
  }

  // Display notification using flutter_local_notifications
  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      String? sound;
      if (Platform.isAndroid) {
        sound =
            android?.sound ?? 'notification'; // fallback to your custom sound
      } else if (Platform.isIOS) {
        sound = message.notification?.apple?.sound?.name ?? 'notification.mp3';
      }

      final androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
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
}
