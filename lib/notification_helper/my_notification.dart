import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitbud/presentation/screens/notification/notifications_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class MyNotification {
  static Future<void> initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize =
        const AndroidInitializationSettings('notification_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse? notificationResponse) {
        Get.offAll(() => const NotificationsScreen());
      },
    );

    _setupMessagingListeners(flutterLocalNotificationsPlugin);
  }

  static void initializeWebMessaging() {
    _setupMessagingListeners(null);
  }

  static void _setupMessagingListeners(
      FlutterLocalNotificationsPlugin? fln) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Get.offAll(() => const NotificationsScreen());
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('onMessage: ${message.data}');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
      }

      if (fln != null && message.notification != null) {
        showNotification(
          message.data,
          message.notification!.title ?? '',
          message.notification!.body ?? '',
          fln,
        );
      }
    });
  }

  static Future<void> showNotification(
    Map<String, dynamic> message,
    String title,
    String body,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    await showBigTextNotification(message, title, body, fln);
  }

  static Future<void> showBigTextNotification(
    Map<String, dynamic> message,
    String title,
    String body,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fitbud_channel',
      'FitBud Notifications',
      importance: Importance.max,
      styleInformation: bigTextStyleInformation,
      priority: Priority.high,
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics);
  }
}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('background message: ${message.data}');
  }
  var androidInitialize =
      const AndroidInitializationSettings('notification_icon');
  var initializationSettings =
      InitializationSettings(android: androidInitialize);

  FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
  await fln.initialize(initializationSettings);

  if (message.notification != null) {
    await MyNotification.showNotification(
      message.data,
      message.notification!.title ?? '',
      message.notification!.body ?? '',
      fln,
    );
  }
}
