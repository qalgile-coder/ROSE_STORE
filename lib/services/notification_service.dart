import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // 2. Local Notifications Initialization
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings);

    // 3. Create Android Notification Channel
    if (!kIsWeb && Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'zen_mart_pro_high_channel',
        'High Importance Notifications',
        description: 'Used for critical order and system updates.',
        importance: Importance.high,
      );

      final dynamic plugin = _localNotifications;
      try {
        final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(channel);
        }
      } catch (e) {
        debugPrint('Error creating notification channel: $e');
      }

      // 4. Listen for Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message, channel);
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.data}');
    });
  }

  void _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
            priority: Priority.high,
            importance: Importance.max,
          ),
        ),
      );
    }
  }

  /// Send a push notification to a specific user
  Future<void> notifyUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Log to user's notification history in Firestore
      await _db.collection('users').doc(userId).collection('notifications').add({
        'title': title,
        'message': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': data,
      });

      // 2. Trigger Push via 'push_notifications' collection (For Cloud Function)
      final userDoc = await _db.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        await _db.collection('push_notifications').add({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }
    } catch (e) {
      debugPrint('Notification error (insufficient permissions?): $e');
    }
  }

  /// Notify all users of a specific role (e.g. Super Admins)
  Future<void> notifyRole({
    required UserRole role,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final users = await _db.collection('users').where('role', isEqualTo: role.name).get();
    
    for (var doc in users.docs) {
      await notifyUser(userId: doc.id, title: title, body: body, data: data);
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  Future<void> saveTokenToFirestore(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('FCM Token Save Error (Non-critical): $e');
    }
  }
}
