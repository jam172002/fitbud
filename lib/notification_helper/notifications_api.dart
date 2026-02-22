import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:developer' as devtools show log;
import 'package:googleapis_auth/auth_io.dart' as auth;


class NotificationsApi {

Future<bool> sendPushMessage({
  required String recipientToken,
  required String title,
  required String body,
}) async {
  final jsonCredentials = await rootBundle
      .loadString('assets/data/fitbud-46f70-3959a9724f68.json');
  final creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);
  
  final client = await auth.clientViaServiceAccount(
    creds,
    ['https://www.googleapis.com/auth/cloud-platform'],
  );
  
  final notificationData = {
    'message': {
      'token': recipientToken,
      'notification': {'title': title, 'body': body}
    },
  };
  
  const String senderId = '590843014671';
  final response = await client.post(
    Uri.parse('https://fcm.googleapis.com/v1/projects/$senderId/messages:send'),
    headers: {
      'content-type': 'application/json',
    },
    body: jsonEncode(notificationData),
  );
  
  client.close();
  if (response.statusCode == 200) {
    return true;
  }

  devtools.log(
      'Notification Sending Error Response status: ${response.statusCode}');
  devtools.log('Notification Response body: ${response.body}');
  return false;
}

  Future<void> sendPushNotification({
    required String nTitle,
    required String nBody,
    required String nType,
    required String nSenderId,
    required String nUserDeviceToken,
    Map<String, dynamic>? nCallInfo,
  }) async {
    final Uri url = Uri.parse('https://fcm.googleapis.com/v1/projects/sobbefy-21978/messages:send');

    await http
        .post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer 764967386373-kpujbavqjdahbfr1ksktofia4id6b9t5.apps.googleusercontent.com',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'title': nTitle,
            'body': nBody,
            'color': '#987dfa',
            'sound': "default"
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            "N_TYPE": nType,
            "N_SENDER_ID": nSenderId,
            'call_info': nCallInfo,
            'status': 'done'
          },
          'to': nUserDeviceToken,
        },
      ),
    )
        .then((http.Response response) {
      if (response.statusCode == 200) {
        debugPrint('sendPushNotification() -> success');
      }
    }).catchError((error) {
      debugPrint('sendPushNotification() -> error: $error');
    });
  }
}
