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
    } else {
      debugPrint('User declined or did not accept notification permission');
      return;
    }

    // 2. Local Notifications Initialization
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings);

    AndroidNotificationChannel? channel;

    // 3. Create Android Notification Channel
    if (!kIsWeb && Platform.isAndroid) {
      channel = const AndroidNotificationChannel(
        'rooz_store_high_channel', // تم تحديث معرف القناة ليتناسب مع مشروعك
        'High Importance Notifications',
        description: 'Used for critical order and system updates.',
        importance: Importance.high,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    // 4. Listen for Foreground Messages (تم فصلها لتعمل باستمرار وبشكل صحيح)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('A new onMessage event was published: ${message.notification?.title}');
      if (channel != null) {
        _showLocalNotification(message, channel);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.data}');
    });

    // 5. الحصول على الرمز وتحديثه تلقائياً عند الإنشاء
    String? token = await getToken();
    debugPrint("FCM Token: $token");
  }

  void _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            priority: Priority.high,
            importance: Importance.max,
          ),
          iOS: const DarwinDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
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
      debugPrint('Notification error: $e');
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
        await _db.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token successfully saved for user: $userId');
      }
    } catch (e) {
      debugPrint('FCM Token Save Error: $e');
    }
  }
}
