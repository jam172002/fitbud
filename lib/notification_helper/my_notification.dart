 import 'dart:io';


import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitbud/presentation/screens/notification/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';


class MyNotification {

  static Future<void> initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    
    // Android settings
    var androidInitialize =
        const AndroidInitializationSettings('notification_icon');

    // iOS settings
    final DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings();

    // Combined initialization settings
    var initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: initializationSettingsDarwin,
    );

    // ✅ Initialize only once
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse? notificationResponse) {
        
          // Navigate when notification is tapped (foreground)
          Get.offAll(() => const NotificationsScreen());
        
      },
    );

    // ✅ Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      
        Get.offAll(() => const NotificationsScreen());
      
      print("onMessageOpenedApp: ${message.data}");
    });

    // ✅ Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: ${message.data}");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      
      MyNotification.showNotification(
        message.data,
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        flutterLocalNotificationsPlugin,
      );
       
    });
  }


  static Future<void> showNotification(Map<String, dynamic> message,String tittle, String body, FlutterLocalNotificationsPlugin? fln) async {
    if(message['image'] != null && message['image'].isNotEmpty) {
      try{
        // await showBigPictureNotificationHiddenLargeIcon(message, fln!);
      }catch(e) {
        await showBigTextNotification(message,tittle, body, fln!);
      }
    }else {
      await showBigTextNotification(message,tittle, body, fln!);
    }
  }

  static Future<void> showTextNotification(Map<String, dynamic> message, FlutterLocalNotificationsPlugin fln) async {
    String? title = message['title'];
    String? body = message['body'];
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', 'your channel name',
      sound: RawResourceAndroidNotificationSound('notification'),
      importance: Importance.max, priority: Priority.high, ticker: 'ticker', playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: 'navigate_to_notifications');
  }

   static Future<void> showBigTextNotification(Map<String, dynamic> message,String tittle,String body, FlutterLocalNotificationsPlugin fln) async {
    // String? _title = message['title'];
    // String _body = message['body'];
    String? title =tittle;
    String body0 = body;
    
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body0, htmlFormatBigText: true,
      contentTitle: title, htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'big text channel id', 'big text channel name', importance: Importance.max,
      styleInformation: bigTextStyleInformation, priority: Priority.high, sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body0, platformChannelSpecifics, );
  }


  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
   
    final File file = File(filePath);
 
    return filePath;
  }

}

Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  print('background: ${message.data}}');
  var androidInitialize = const AndroidInitializationSettings('notification_icon');
  
  var initializationsSettings = InitializationSettings(android: androidInitialize);


  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  MyNotification.showNotification(message.data,message.notification!.title.toString(),message.notification!.body.toString(), flutterLocalNotificationsPlugin);
}