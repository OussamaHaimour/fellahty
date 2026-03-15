import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // IMPORTANT: For production, this should NEVER be in the app.
  // This is only for the "Trial/Testing" phase as requested.
  static const String _serviceAccountJson = '''
{
  "project_id": "YOUR_PROJECT_ID",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nYOUR_PRIVATE_KEY\\n-----END PRIVATE KEY-----\\n",
  "client_email": "YOUR_CLIENT_EMAIL"
}
''';

  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    }

    // Listen for incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Message received: ${message.notification?.title}");
    });
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }
  }

  static Future<String> _getAccessToken() async {
    final account = json.decode(_serviceAccountJson);
    final credentials = ServiceAccountCredentials.fromJson(account);
    final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

    final client = await clientViaServiceAccount(credentials, scopes);
    return client.credentials.accessToken.data;
  }

  static Future<void> sendNotification({
    required String targetToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      final projectId = json.decode(_serviceAccountJson)['project_id'];

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'token': targetToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data?.map((key, value) => MapEntry(key, value.toString())) ?? {},
          }
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("FCM Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  // Helper to notify all workers in a region
  static Future<void> notifyWorkersInRegion(String region, String title, String body) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'worker')
        .where('region', isEqualTo: region)
        .get();

    for (var doc in snapshot.docs) {
      String? token = doc.data()['fcmToken'];
      if (token != null) {
        await sendNotification(targetToken: token, title: title, body: body);
      }
    }
  }
}
